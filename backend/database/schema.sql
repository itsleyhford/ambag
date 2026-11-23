-- backend/database/schema.sql
-- AMBAG database schema (assignment slice: 13 of the 28 ERD tables).
--
-- Portable on purpose: plain MySQL 8 SQL with no triggers and no stored
-- procedures, so the same file runs on local MySQL, TiDB Cloud and Aiven.
-- Business rules (one primary owner, append-only log, ...) are enforced in
-- the Express services layer.
--
-- WARNING: this file DROPS and recreates every table. Run it only on a
-- development database. `npm run db:setup` refuses to run in production.
--
-- `user` and `class` are written in backticks because they are MySQL keywords.

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS flag;
DROP TABLE IF EXISTS excuse;
DROP TABLE IF EXISTS activity_event;
DROP TABLE IF EXISTS work_receipt;
DROP TABLE IF EXISTS task_owner;
DROP TABLE IF EXISTS task;
DROP TABLE IF EXISTS group_member;
DROP TABLE IF EXISTS project_group;
DROP TABLE IF EXISTS milestone;
DROP TABLE IF EXISTS project;
DROP TABLE IF EXISTS enrollment;
DROP TABLE IF EXISTS `class`;
DROP TABLE IF EXISTS `user`;
SET FOREIGN_KEY_CHECKS = 1;

-- Accounts. Teachers start as 'pending' until an admin approves them.
CREATE TABLE `user` (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name          VARCHAR(80)  NOT NULL,
  email         VARCHAR(254) NOT NULL,
  password_hash VARCHAR(100) NOT NULL,
  role          ENUM('student', 'teacher', 'admin') NOT NULL DEFAULT 'student',
  status        ENUM('active', 'pending', 'inactive') NOT NULL DEFAULT 'active',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_user_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- A teacher's class. Students join with `code`.
CREATE TABLE `class` (
  id                   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  teacher_id           INT UNSIGNED NOT NULL,
  name                 VARCHAR(120) NOT NULL,
  code                 VARCHAR(12)  NOT NULL,
  excuse_backdate_days TINYINT UNSIGNED NOT NULL DEFAULT 7, -- how far back an excuse may start
  created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_class_code (code),
  KEY idx_class_teacher (teacher_id),
  CONSTRAINT fk_class_teacher FOREIGN KEY (teacher_id) REFERENCES `user` (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE enrollment (
  class_id  INT UNSIGNED NOT NULL,
  user_id   INT UNSIGNED NOT NULL,
  joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (class_id, user_id),
  KEY idx_enrollment_user (user_id),
  CONSTRAINT fk_enrollment_class FOREIGN KEY (class_id) REFERENCES `class` (id) ON DELETE CASCADE,
  CONSTRAINT fk_enrollment_user  FOREIGN KEY (user_id)  REFERENCES `user` (id)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE project (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  class_id   INT UNSIGNED NOT NULL,
  title      VARCHAR(150) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_project_class (class_id),
  CONSTRAINT fk_project_class FOREIGN KEY (class_id) REFERENCES `class` (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE milestone (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  project_id INT UNSIGNED NOT NULL,
  title      VARCHAR(120) NOT NULL,
  due_date   DATE NOT NULL,
  PRIMARY KEY (id),
  KEY idx_milestone_project (project_id),
  CONSTRAINT fk_milestone_project FOREIGN KEY (project_id) REFERENCES project (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Named project_group because GROUP is a reserved word in MySQL.
CREATE TABLE project_group (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  project_id INT UNSIGNED NOT NULL,
  name       VARCHAR(80) NOT NULL,
  PRIMARY KEY (id),
  KEY idx_group_project (project_id),
  CONSTRAINT fk_group_project FOREIGN KEY (project_id) REFERENCES project (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- project_id is repeated here so the UNIQUE key can enforce
-- "a student belongs to only one group per project".
CREATE TABLE group_member (
  group_id   INT UNSIGNED NOT NULL,
  user_id    INT UNSIGNED NOT NULL,
  project_id INT UNSIGNED NOT NULL,
  joined_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (group_id, user_id),
  UNIQUE KEY uq_member_one_group_per_project (project_id, user_id),
  KEY idx_member_user (user_id),
  CONSTRAINT fk_member_group   FOREIGN KEY (group_id)   REFERENCES project_group (id) ON DELETE CASCADE,
  CONSTRAINT fk_member_user    FOREIGN KEY (user_id)    REFERENCES `user` (id)        ON DELETE CASCADE,
  CONSTRAINT fk_member_project FOREIGN KEY (project_id) REFERENCES project (id)       ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Size S/M/L = 1/3/5 effort points (points are computed by the server).
CREATE TABLE task (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  milestone_id INT UNSIGNED NOT NULL,
  group_id     INT UNSIGNED NOT NULL,
  title        VARCHAR(120) NOT NULL,
  size         ENUM('S', 'M', 'L') NOT NULL,
  points       TINYINT UNSIGNED NOT NULL,
  status       ENUM('todo', 'in_progress', 'done') NOT NULL DEFAULT 'todo',
  deadline     DATE NULL,
  created_by   INT UNSIGNED NOT NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_task_group (group_id),
  KEY idx_task_milestone (milestone_id),
  CONSTRAINT fk_task_milestone FOREIGN KEY (milestone_id) REFERENCES milestone (id)     ON DELETE CASCADE,
  CONSTRAINT fk_task_group     FOREIGN KEY (group_id)     REFERENCES project_group (id) ON DELETE CASCADE,
  CONSTRAINT fk_task_creator   FOREIGN KEY (created_by)   REFERENCES `user` (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Who owns a task. Rule (services): exactly one 'primary' owner per task,
-- and shares on a task total 100%.
CREATE TABLE task_owner (
  task_id       INT UNSIGNED NOT NULL,
  user_id       INT UNSIGNED NOT NULL,
  owner_type    ENUM('primary', 'co') NOT NULL,
  share_percent TINYINT UNSIGNED NOT NULL,
  claimed_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  confirmed_at  DATETIME NULL,
  PRIMARY KEY (task_id, user_id),
  KEY idx_owner_user (user_id),
  CONSTRAINT fk_owner_task FOREIGN KEY (task_id) REFERENCES task (id)   ON DELETE CASCADE,
  CONSTRAINT fk_owner_user FOREIGN KEY (user_id) REFERENCES `user` (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Proof of work. A task cannot be Done (or deleted) once it has receipts.
-- No ON DELETE CASCADE: a task with receipts must not be deletable.
CREATE TABLE work_receipt (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  task_id    INT UNSIGNED NOT NULL,
  user_id    INT UNSIGNED NOT NULL,
  type       ENUM('file', 'link', 'note') NOT NULL,
  content    VARCHAR(1000) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_receipt_task (task_id),
  CONSTRAINT fk_receipt_task FOREIGN KEY (task_id) REFERENCES task (id),
  CONSTRAINT fk_receipt_user FOREIGN KEY (user_id) REFERENCES `user` (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Append-only contribution log. The app only ever INSERTs here.
-- ref_id has NO foreign key on purpose, so the log entry for a deleted task
-- is kept. Corrections are new rows that point to the old one.
CREATE TABLE activity_event (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_id          INT UNSIGNED NOT NULL,
  user_id           INT UNSIGNED NOT NULL,
  type              VARCHAR(40) NOT NULL,
  ref_id            INT UNSIGNED NULL,
  source            VARCHAR(20) NOT NULL DEFAULT 'web',
  occurred_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  received_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  corrects_event_id BIGINT UNSIGNED NULL,
  synced_later      BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id),
  KEY idx_event_group_time (group_id, occurred_at),
  KEY idx_event_user (user_id),
  CONSTRAINT fk_event_group    FOREIGN KEY (group_id)          REFERENCES project_group (id),
  CONSTRAINT fk_event_user     FOREIGN KEY (user_id)           REFERENCES `user` (id),
  CONSTRAINT fk_event_corrects FOREIGN KEY (corrects_event_id) REFERENCES activity_event (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Excuse Shield (Feature 6.4): a student asks; the class teacher decides.
CREATE TABLE excuse (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_id      INT UNSIGNED NOT NULL,
  user_id       INT UNSIGNED NOT NULL,
  reason_type   ENUM('illness', 'power_outage', 'no_internet', 'family_emergency', 'other') NOT NULL,
  details       VARCHAR(500) NOT NULL,
  start_date    DATE NOT NULL,
  end_date      DATE NOT NULL,
  status        ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
  decided_by    INT UNSIGNED NULL,
  decided_at    DATETIME NULL,
  decision_note VARCHAR(300) NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_excuse_group_status (group_id, status),
  KEY idx_excuse_user (user_id),
  CONSTRAINT fk_excuse_group   FOREIGN KEY (group_id)   REFERENCES project_group (id),
  CONSTRAINT fk_excuse_user    FOREIGN KEY (user_id)    REFERENCES `user` (id),
  CONSTRAINT fk_excuse_decider FOREIGN KEY (decided_by) REFERENCES `user` (id),
  CONSTRAINT chk_excuse_dates  CHECK (end_date >= start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Early-warning flags (Feature 6.3). Approved excuses change matching open
-- flags to 'excused' (linked by excuse_id) instead of deleting them.
CREATE TABLE flag (
  id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_id  INT UNSIGNED NOT NULL,
  user_id   INT UNSIGNED NOT NULL,
  flag_type ENUM('inactive', 'missed_deadline', 'no_claims', 'imbalance') NOT NULL,
  flag_date DATE NOT NULL,
  raised_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status    ENUM('open', 'resolved', 'excused') NOT NULL DEFAULT 'open',
  excuse_id INT UNSIGNED NULL,
  PRIMARY KEY (id),
  KEY idx_flag_user_status_date (user_id, status, flag_date),
  KEY idx_flag_group (group_id),
  CONSTRAINT fk_flag_group  FOREIGN KEY (group_id)  REFERENCES project_group (id),
  CONSTRAINT fk_flag_user   FOREIGN KEY (user_id)   REFERENCES `user` (id),
  CONSTRAINT fk_flag_excuse FOREIGN KEY (excuse_id) REFERENCES excuse (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
