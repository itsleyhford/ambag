-- backend/database/seed.sql
-- Demo data so the app can be shown right after setup (the assignment allows
-- inserting records directly). Run AFTER schema.sql.
--
-- Every demo account uses the password: Ambag123!
-- (stored only as a bcrypt hash below, never as plain text)
--
-- Dates are relative to CURDATE() so the demo flags always look recent.

INSERT INTO `user` (id, name, email, password_hash, role, status) VALUES
  (1, 'Admin Ambag',     'admin@ambag.test',   '$2b$12$23oLoAasLqMsymYKCz2e7uV/tAAt4tSH9R1rYNkX.S.clMjR9tJj2', 'admin',   'active'),
  (2, 'Ma''am Reyes',    'teacher@ambag.test', '$2b$12$23oLoAasLqMsymYKCz2e7uV/tAAt4tSH9R1rYNkX.S.clMjR9tJj2', 'teacher', 'active'),
  (3, 'Ana Santos',      'ana@ambag.test',     '$2b$12$23oLoAasLqMsymYKCz2e7uV/tAAt4tSH9R1rYNkX.S.clMjR9tJj2', 'student', 'active'),
  (4, 'Ben Cruz',        'ben@ambag.test',     '$2b$12$23oLoAasLqMsymYKCz2e7uV/tAAt4tSH9R1rYNkX.S.clMjR9tJj2', 'student', 'active'),
  (5, 'Carla Villanueva','carla@ambag.test',   '$2b$12$23oLoAasLqMsymYKCz2e7uV/tAAt4tSH9R1rYNkX.S.clMjR9tJj2', 'student', 'active'),
  (6, 'Dan Lim',         'dan@ambag.test',     '$2b$12$23oLoAasLqMsymYKCz2e7uV/tAAt4tSH9R1rYNkX.S.clMjR9tJj2', 'student', 'active');

INSERT INTO `class` (id, teacher_id, name, code, excuse_backdate_days) VALUES
  (1, 2, 'BSIT-3A Capstone', 'AMBAG3A', 7);

INSERT INTO enrollment (class_id, user_id) VALUES
  (1, 3), (1, 4), (1, 5), (1, 6);

INSERT INTO project (id, class_id, title) VALUES
  (1, 1, 'Ambag Capstone');

INSERT INTO milestone (id, project_id, title, due_date) VALUES
  (1, 1, 'Chapter 1-3',  DATE_ADD(CURDATE(), INTERVAL 14 DAY)),
  (2, 1, 'Prototype',    DATE_ADD(CURDATE(), INTERVAL 35 DAY));

INSERT INTO project_group (id, project_id, name) VALUES
  (1, 1, 'Group 1'),
  (2, 1, 'Group 2');

INSERT INTO group_member (group_id, user_id, project_id) VALUES
  (1, 3, 1), (1, 4, 1), (1, 5, 1),
  (2, 6, 1);

-- Group 1 has 5 tasks, Group 2 has 1.
INSERT INTO task (id, milestone_id, group_id, title, size, points, status, deadline, created_by) VALUES
  (1, 1, 1, 'Write Chapter 1 introduction', 'M', 3, 'todo',        DATE_ADD(CURDATE(), INTERVAL 7 DAY),  3),
  (2, 1, 1, 'Gather related literature',    'L', 5, 'in_progress', DATE_ADD(CURDATE(), INTERVAL 10 DAY), 3),
  (3, 1, 1, 'Draft survey questionnaire',   'S', 1, 'todo',        DATE_ADD(CURDATE(), INTERVAL 5 DAY),  4),
  (4, 1, 1, 'Design database ERD',          'M', 3, 'todo',        DATE_ADD(CURDATE(), INTERVAL 12 DAY), 3),
  (5, 2, 1, 'Prototype login screen',       'L', 5, 'todo',        NULL,                                 5),
  (6, 1, 2, 'Group 2 project outline',      'M', 3, 'todo',        DATE_ADD(CURDATE(), INTERVAL 6 DAY),  6);

INSERT INTO task_owner (task_id, user_id, owner_type, share_percent) VALUES
  (1, 3, 'primary', 100),
  (2, 3, 'primary', 100),
  (3, 4, 'primary', 100),
  (4, 3, 'primary', 100),
  (5, 5, 'primary', 100),
  (6, 6, 'primary', 100);

-- Task 4 already has an early draft attached, so it can no longer be deleted.
INSERT INTO work_receipt (task_id, user_id, type, content) VALUES
  (4, 3, 'link', 'https://example.com/ambag-erd-draft');

INSERT INTO activity_event (group_id, user_id, type, ref_id) VALUES
  (1, 3, 'task_created', 1),
  (1, 3, 'task_created', 2),
  (1, 4, 'task_created', 3),
  (1, 3, 'task_created', 4),
  (1, 5, 'task_created', 5),
  (2, 6, 'task_created', 6),
  (1, 3, 'receipt_added', 4);

-- Early-warning flags for the excuse demo.
-- Ana: 4 open flags in the last 4 days, 1 older open flag, 1 resolved flag.
-- Ben: 1 open flag (must never be touched by Ana's excuse).
INSERT INTO flag (group_id, user_id, flag_type, flag_date, status) VALUES
  (1, 3, 'inactive',        DATE_SUB(CURDATE(), INTERVAL 3 DAY),  'open'),
  (1, 3, 'inactive',        DATE_SUB(CURDATE(), INTERVAL 2 DAY),  'open'),
  (1, 3, 'missed_deadline', DATE_SUB(CURDATE(), INTERVAL 1 DAY),  'open'),
  (1, 3, 'inactive',        CURDATE(),                            'open'),
  (1, 3, 'no_claims',       DATE_SUB(CURDATE(), INTERVAL 12 DAY), 'open'),
  (1, 3, 'inactive',        DATE_SUB(CURDATE(), INTERVAL 2 DAY),  'resolved'),
  (1, 4, 'inactive',        DATE_SUB(CURDATE(), INTERVAL 1 DAY),  'open');
