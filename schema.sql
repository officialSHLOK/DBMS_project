-- ============================================================
-- Student Project Management System — SQL DDL
-- Compatible with: MySQL 8.0+
-- ============================================================

-- Drop existing tables (in reverse dependency order) for clean re-creation
DROP TABLE IF EXISTS collaboration;
DROP TABLE IF EXISTS project_progress;
DROP TABLE IF EXISTS meeting_log;
DROP TABLE IF EXISTS coordinator_assignment;
DROP TABLE IF EXISTS coordinator;
DROP TABLE IF EXISTS project_guide;
DROP TABLE IF EXISTS project_team;
DROP TABLE IF EXISTS project;
DROP TABLE IF EXISTS faculty;
DROP TABLE IF EXISTS student;

-- ============================================================
-- 1. STUDENT
-- ============================================================
CREATE TABLE student (
    student_id      INT             AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100)    NOT NULL,
    email           VARCHAR(100)    NOT NULL UNIQUE,
    phone           VARCHAR(15)     UNIQUE,
    department      VARCHAR(50)     NOT NULL,
    year_of_study   INT             NOT NULL CHECK (year_of_study BETWEEN 1 AND 4),
    enrollment_year YEAR            NOT NULL
) ENGINE=InnoDB;

-- ============================================================
-- 2. PROJECT
-- ============================================================
CREATE TABLE project (
    project_id  INT                                                      AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(200)                                             NOT NULL,
    description TEXT,
    type        ENUM('application', 'research')                          NOT NULL,
    start_date  DATE                                                     NOT NULL,
    end_date    DATE,
    status      ENUM('proposed', 'active', 'completed', 'on_hold')      NOT NULL DEFAULT 'proposed',

    CONSTRAINT chk_project_dates CHECK (end_date IS NULL OR end_date >= start_date)
) ENGINE=InnoDB;

-- ============================================================
-- 3. FACULTY
-- ============================================================
CREATE TABLE faculty (
    faculty_id  INT             AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100)    NOT NULL,
    email       VARCHAR(100)    NOT NULL UNIQUE,
    department  VARCHAR(50)     NOT NULL,
    designation VARCHAR(50)     NOT NULL,
    expertise   VARCHAR(200)
) ENGINE=InnoDB;

-- ============================================================
-- 4. PROJECT_TEAM  (Student ↔ Project — M:N)
--    Constraint: a student can be active in only ONE project at a time.
-- ============================================================
CREATE TABLE project_team (
    team_id     INT                                                             AUTO_INCREMENT PRIMARY KEY,
    student_id  INT                                                             NOT NULL,
    project_id  INT                                                             NOT NULL,
    role        ENUM('team_lead', 'developer', 'researcher', 'tester', 'designer') NOT NULL,
    joined_date DATE                                                            NOT NULL,
    is_active   TINYINT(1)                                                      NOT NULL DEFAULT 1,

    CONSTRAINT fk_pt_student  FOREIGN KEY (student_id) REFERENCES student(student_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pt_project  FOREIGN KEY (project_id) REFERENCES project(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    -- ensures one active project per student (MySQL 8.0.16+ supports CHECK)
    -- We also create a unique partial-index workaround via generated column below.
    INDEX idx_pt_student (student_id),
    INDEX idx_pt_project (project_id)
) ENGINE=InnoDB;

-- Workaround for MySQL partial unique index:
-- A generated column that is NULL when inactive, student_id when active.
-- UNIQUE on a nullable column ignores NULLs, achieving the partial-unique effect.
ALTER TABLE project_team
    ADD COLUMN active_student_id INT
        GENERATED ALWAYS AS (CASE WHEN is_active = 1 THEN student_id ELSE NULL END) STORED,
    ADD CONSTRAINT uq_one_active_project UNIQUE (active_student_id);

-- ============================================================
-- 5. PROJECT_GUIDE  (Faculty ↔ Project — M:N)
-- ============================================================
CREATE TABLE project_guide (
    guide_id      INT         AUTO_INCREMENT PRIMARY KEY,
    faculty_id    INT         NOT NULL,
    project_id    INT         NOT NULL,
    assigned_date DATE        NOT NULL,
    is_active     TINYINT(1)  NOT NULL DEFAULT 1,

    CONSTRAINT fk_pg_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pg_project FOREIGN KEY (project_id) REFERENCES project(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT uq_guide_assignment UNIQUE (faculty_id, project_id)
) ENGINE=InnoDB;

-- ============================================================
-- 6. COORDINATOR  (Subset of Faculty)
-- ============================================================
CREATE TABLE coordinator (
    coordinator_id INT         AUTO_INCREMENT PRIMARY KEY,
    faculty_id     INT         NOT NULL UNIQUE,
    appointed_date DATE        NOT NULL,
    is_active      TINYINT(1)  NOT NULL DEFAULT 1,

    CONSTRAINT fk_coord_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 7. COORDINATOR_ASSIGNMENT  (Coordinator ↔ Project — M:N)
-- ============================================================
CREATE TABLE coordinator_assignment (
    assignment_id  INT   AUTO_INCREMENT PRIMARY KEY,
    coordinator_id INT   NOT NULL,
    project_id     INT   NOT NULL,
    assigned_date  DATE  NOT NULL,

    CONSTRAINT fk_ca_coordinator FOREIGN KEY (coordinator_id) REFERENCES coordinator(coordinator_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ca_project     FOREIGN KEY (project_id)     REFERENCES project(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT uq_coord_project UNIQUE (coordinator_id, project_id)
) ENGINE=InnoDB;

-- ============================================================
-- 8. MEETING_LOG
-- ============================================================
CREATE TABLE meeting_log (
    meeting_id    INT           AUTO_INCREMENT PRIMARY KEY,
    coordinator_id INT          NOT NULL,
    project_id    INT           NOT NULL,
    meeting_date  DATE          NOT NULL,
    agenda        VARCHAR(300)  NOT NULL,
    feedback      TEXT,
    action_items  TEXT,

    CONSTRAINT fk_ml_coordinator FOREIGN KEY (coordinator_id) REFERENCES coordinator(coordinator_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ml_project     FOREIGN KEY (project_id)     REFERENCES project(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    INDEX idx_ml_project_date (project_id, meeting_date)
) ENGINE=InnoDB;

-- ============================================================
-- 9. PROJECT_PROGRESS
-- ============================================================
CREATE TABLE project_progress (
    progress_id      INT                                           AUTO_INCREMENT PRIMARY KEY,
    project_id       INT                                           NOT NULL,
    update_date      DATE                                          NOT NULL,
    description      TEXT                                          NOT NULL,
    milestone_title  VARCHAR(200),
    milestone_status ENUM('pending', 'in_progress', 'completed')   DEFAULT 'pending',
    challenges       TEXT,

    CONSTRAINT fk_pp_project FOREIGN KEY (project_id) REFERENCES project(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    INDEX idx_pp_project_date (project_id, update_date)
) ENGINE=InnoDB;

-- ============================================================
-- 10. COLLABORATION  (Project ↔ Project — M:N self-referencing)
-- ============================================================
CREATE TABLE collaboration (
    collaboration_id INT                                                            AUTO_INCREMENT PRIMARY KEY,
    project_id_1     INT                                                            NOT NULL,
    project_id_2     INT                                                            NOT NULL,
    collab_type      ENUM('resource_sharing', 'joint_research', 'joint_development') NOT NULL,
    description      TEXT,
    start_date       DATE                                                           NOT NULL,
    end_date         DATE,

    CONSTRAINT fk_collab_p1 FOREIGN KEY (project_id_1) REFERENCES project(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_collab_p2 FOREIGN KEY (project_id_2) REFERENCES project(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    -- Prevent self-collaboration and duplicate reverse pairs
    CONSTRAINT chk_collab_diff CHECK (project_id_1 < project_id_2),
    -- Prevent duplicate collaborations
    CONSTRAINT uq_collaboration UNIQUE (project_id_1, project_id_2, collab_type)
) ENGINE=InnoDB;

-- ============================================================
-- Additional Useful Indexes
-- ============================================================
CREATE INDEX idx_project_type   ON project(type);
CREATE INDEX idx_project_status ON project(status);


-- ============================================================
-- SAMPLE DATA
-- ============================================================

-- Students
INSERT INTO student (name, email, phone, department, year_of_study, enrollment_year) VALUES
('Shlok',              'aarav.sharma@eng.edu',    '9876543210', 'Computer Science', 3, 2023),
('Shubham Nagpal',     'priya.patel@eng.edu',     '9876543211', 'Computer Science', 3, 2023),
('Kunj Singhal',       'rohan.mehta@eng.edu',      '9876543212', 'Information Technology', 3, 2023),
('Sneha Desai',     'sneha.desai@eng.edu',      '9876543213', 'Electronics', 2, 2024),
('Vikram Singh',    'vikram.singh@eng.edu',     '9876543214', 'Computer Science', 4, 2022),
('Ananya Gupta',    'ananya.gupta@eng.edu',     '9876543215', 'Information Technology', 4, 2022);

-- Faculty
INSERT INTO faculty (name, email, department, designation, expertise) VALUES
('Dr. Rajesh Kumar',   'rajesh.kumar@eng.edu',   'Computer Science',        'Professor',           'Machine Learning, AI'),
('Dr. Meena Iyer',     'meena.iyer@eng.edu',     'Computer Science',        'Associate Professor', 'Software Engineering'),
('Dr. Suresh Nair',    'suresh.nair@eng.edu',    'Information Technology',   'Professor',           'Data Mining, Big Data'),
('Dr. Kavita Rao',     'kavita.rao@eng.edu',     'Electronics',             'Assistant Professor', 'IoT, Embedded Systems');

-- Projects
INSERT INTO project (title, description, type, start_date, end_date, status) VALUES
('Smart Campus App',
 'A mobile application for campus navigation, event management, and resource booking.',
 'application', '2025-08-01', '2026-04-30', 'active'),

('ML-Based Plagiarism Detection',
 'Research on using transformer models to detect plagiarism in academic submissions.',
 'research', '2025-09-01', '2026-05-31', 'active'),

('IoT Lab Monitoring System',
 'An IoT-based system to monitor temperature, humidity and equipment usage in labs.',
 'application', '2025-07-15', NULL, 'proposed');

-- Project Team assignments
INSERT INTO project_team (student_id, project_id, role, joined_date) VALUES
(1, 1, 'team_lead',  '2025-08-01'),
(2, 1, 'developer',  '2025-08-01'),
(3, 1, 'designer',   '2025-08-05'),
(5, 2, 'team_lead',  '2025-09-01'),
(6, 2, 'researcher', '2025-09-01');
-- Student 4 (Sneha) is not assigned yet — available for project 3

-- Project Guides
INSERT INTO project_guide (faculty_id, project_id, assigned_date) VALUES
(2, 1, '2025-08-01'),   -- Dr. Meena guides Smart Campus App
(1, 2, '2025-09-01');   -- Dr. Rajesh guides ML Plagiarism Detection

-- Coordinators
INSERT INTO coordinator (faculty_id, appointed_date) VALUES
(3, '2025-06-01'),   -- Dr. Suresh Nair
(4, '2025-06-01');   -- Dr. Kavita Rao

-- Coordinator Assignments
INSERT INTO coordinator_assignment (coordinator_id, project_id, assigned_date) VALUES
(1, 1, '2025-08-01'),   -- Dr. Suresh oversees Smart Campus App
(1, 2, '2025-09-01'),   -- Dr. Suresh oversees ML Plagiarism project
(2, 1, '2025-08-01');   -- Dr. Kavita also oversees Smart Campus App

-- Meeting Logs
INSERT INTO meeting_log (coordinator_id, project_id, meeting_date, agenda, feedback, action_items) VALUES
(1, 1, '2025-09-15', 'Sprint 1 Review',
 'Good progress on UI wireframes. Backend API design needs more detail.',
 'Finalize API endpoints by Sep 25. Start database design.'),
(1, 2, '2025-10-01', 'Literature Review Status',
 'Team has reviewed 12 papers. Need to narrow scope to transformer-based methods.',
 'Submit refined problem statement by Oct 10.'),
(2, 1, '2025-10-10', 'Mid-semester Check',
 'App prototype demo was impressive. Need to add accessibility features.',
 'Integrate screen reader support. Plan user testing.');

-- Project Progress
INSERT INTO project_progress (project_id, update_date, description, milestone_title, milestone_status, challenges) VALUES
(1, '2025-09-01', 'Project kickoff completed. Team formed and roles assigned.',
 'Project Kickoff', 'completed', NULL),
(1, '2025-09-30', 'UI wireframes finalized. Database schema designed.',
 'Design Phase', 'completed', 'Deciding between SQL and NoSQL for the backend.'),
(1, '2025-10-30', 'Core modules — navigation and event management — under development.',
 'Development Sprint 1', 'in_progress', 'Integrating campus map API proved more complex than expected.'),
(2, '2025-09-15', 'Team completed initial literature survey of 12 papers.',
 'Literature Review', 'completed', NULL),
(2, '2025-10-20', 'Experimenting with BERT and GPT embeddings for similarity detection.',
 'Model Experimentation', 'in_progress', 'High computational cost — exploring cloud GPU options.');

-- Collaboration
INSERT INTO collaboration (project_id_1, project_id_2, collab_type, description, start_date) VALUES
(1, 2, 'resource_sharing',
 'Smart Campus App team shares their student database module with the Plagiarism Detection team for testing on real submissions.',
 '2025-10-01');
