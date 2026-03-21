# Logical Schema — Relational Model

## Student Project Management System

This document defines the relational model derived from the conceptual ER diagram. All tables are in **Third Normal Form (3NF)**.

---

## Table Definitions

### 1. `student`

| Column | Type | Constraints |
|---|---|---|
| `student_id` | INT | PRIMARY KEY, AUTO_INCREMENT |
| `name` | VARCHAR(100) | NOT NULL |
| `email` | VARCHAR(100) | NOT NULL, UNIQUE |
| `phone` | VARCHAR(15) | UNIQUE |
| `department` | VARCHAR(50) | NOT NULL |
| `year_of_study` | INT | NOT NULL, CHECK (1–4) |
| `enrollment_year` | YEAR | NOT NULL |

---

### 2. `project`

| Column | Type | Constraints |
|---|---|---|
| `project_id` | INT | PRIMARY KEY, AUTO_INCREMENT |
| `title` | VARCHAR(200) | NOT NULL |
| `description` | TEXT | |
| `type` | ENUM('application','research') | NOT NULL |
| `start_date` | DATE | NOT NULL |
| `end_date` | DATE | |
| `status` | ENUM('proposed','active','completed','on_hold') | NOT NULL, DEFAULT 'proposed' |

**CHECK**: `end_date` ≥ `start_date` (when `end_date` is not NULL)

---

### 3. `faculty`

| Column | Type | Constraints |
|---|---|---|
| `faculty_id` | INT | PRIMARY KEY, AUTO_INCREMENT |
| `name` | VARCHAR(100) | NOT NULL |
| `email` | VARCHAR(100) | NOT NULL, UNIQUE |
| `department` | VARCHAR(50) | NOT NULL |
| `designation` | VARCHAR(50) | NOT NULL |
| `expertise` | VARCHAR(200) | |

---

### 4. `project_team`

| Column | Type | Constraints |
|---|---|---|
| `team_id` | INT | PRIMARY KEY, AUTO_INCREMENT |
| `student_id` | INT | FK → `student(student_id)`, NOT NULL |
| `project_id` | INT | FK → `project(project_id)`, NOT NULL |
| `role` | ENUM('team_lead','developer','researcher','tester','designer') | NOT NULL |
| `joined_date` | DATE | NOT NULL |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |

**Constraint**: UNIQUE(`student_id`, `is_active`) WHERE `is_active = 1` — ensures a student participates in only one active project at a time.

---

### 5. `project_guide`

| Column | Type | Constraints |
|---|---|---|
| `guide_id` | INT | PRIMARY KEY, AUTO_INCREMENT |
| `faculty_id` | INT | FK → `faculty(faculty_id)`, NOT NULL |
| `project_id` | INT | FK → `project(project_id)`, NOT NULL |
| `assigned_date` | DATE | NOT NULL |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |

**Constraint**: UNIQUE(`faculty_id`, `project_id`) — prevents duplicate guide assignments.

---

### 6. `coordinator`

| Column | Type | Constraints |
|---|---|---|
| `coordinator_id` | INT | PRIMARY KEY, AUTO_INCREMENT |
| `faculty_id` | INT | FK → `faculty(faculty_id)`, NOT NULL, UNIQUE |
| `appointed_date` | DATE | NOT NULL |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |

**Note**: A faculty member can be a coordinator **at most once** (UNIQUE on `faculty_id`).

---

### 7. `coordinator_assignment`

| Column | Type | Constraints |
|---|---|---|
| `assignment_id` | INT | PRIMARY KEY, AUTO_INCREMENT |
| `coordinator_id` | INT | FK → `coordinator(coordinator_id)`, NOT NULL |
| `project_id` | INT | FK → `project(project_id)`, NOT NULL |
| `assigned_date` | DATE | NOT NULL |

**Constraint**: UNIQUE(`coordinator_id`, `project_id`)

---

### 8. `meeting_log`

| Column | Type | Constraints |
|---|---|---|
| `meeting_id` | INT | PRIMARY KEY, AUTO_INCREMENT |
| `coordinator_id` | INT | FK → `coordinator(coordinator_id)`, NOT NULL |
| `project_id` | INT | FK → `project(project_id)`, NOT NULL |
| `meeting_date` | DATE | NOT NULL |
| `agenda` | VARCHAR(300) | NOT NULL |
| `feedback` | TEXT | |
| `action_items` | TEXT | |

---

### 9. `project_progress`

| Column | Type | Constraints |
|---|---|---|
| `progress_id` | INT | PRIMARY KEY, AUTO_INCREMENT |
| `project_id` | INT | FK → `project(project_id)`, NOT NULL |
| `update_date` | DATE | NOT NULL |
| `description` | TEXT | NOT NULL |
| `milestone_title` | VARCHAR(200) | |
| `milestone_status` | ENUM('pending','in_progress','completed') | DEFAULT 'pending' |
| `challenges` | TEXT | |

---

### 10. `collaboration`

| Column | Type | Constraints |
|---|---|---|
| `collaboration_id` | INT | PRIMARY KEY, AUTO_INCREMENT |
| `project_id_1` | INT | FK → `project(project_id)`, NOT NULL |
| `project_id_2` | INT | FK → `project(project_id)`, NOT NULL |
| `collab_type` | ENUM('resource_sharing','joint_research','joint_development') | NOT NULL |
| `description` | TEXT | |
| `start_date` | DATE | NOT NULL |
| `end_date` | DATE | |

**CHECK**: `project_id_1` < `project_id_2` — prevents duplicate/reverse entries and self-collaboration.

---

## Integrity Constraints Summary

| Rule | Implementation |
|---|---|
| One active project per student | Conditional UNIQUE on `project_team(student_id)` where `is_active = 1` |
| Faculty can guide multiple projects | No unique constraint on `faculty_id` alone in `project_guide` |
| No duplicate guide assignment | UNIQUE(`faculty_id`, `project_id`) in `project_guide` |
| No self-collaboration | CHECK `project_id_1 < project_id_2` in `collaboration` |
| Valid project dates | CHECK `end_date >= start_date` in `project` |
| Valid year of study | CHECK `year_of_study BETWEEN 1 AND 4` in `student` |

---

## Indexes for Performance

| Table | Index | Purpose |
|---|---|---|
| `project_team` | `idx_pt_student` on `student_id` | Fast student lookup |
| `project_team` | `idx_pt_project` on `project_id` | Fast team member lookup |
| `project` | `idx_project_type` on `type` | Filter by project type |
| `project` | `idx_project_status` on `status` | Filter by status |
| `project_progress` | `idx_pp_project_date` on (`project_id`, `update_date`) | Timeline queries |
| `meeting_log` | `idx_ml_project_date` on (`project_id`, `meeting_date`) | Meeting history |

---

## Normalization Notes

- **1NF**: All attributes are atomic; no repeating groups.
- **2NF**: All non-key attributes are fully functionally dependent on the entire primary key.
- **3NF**: No transitive dependencies — e.g., `faculty` details are stored in the `faculty` table, not repeated in `project_guide` or `coordinator`.
