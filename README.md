# Student Project Management System — Database Design

A relational database system to manage student projects within 4-year engineering degree programs.

## 📁 Project Files

| File | Description |
|---|---|
| [`er_diagram.md`](er_diagram.md) | **Conceptual Schema** — ER diagram (Mermaid) with entity descriptions and relationship rules |
| [`logical_schema.md`](logical_schema.md) | **Logical Schema** — Relational model with table definitions, constraints, indexes, and normalization notes |
| [`schema.sql`](schema.sql) | **SQL DDL** — MySQL 8.0+ compatible CREATE TABLE statements, constraints, and sample data |

## 🏗️ Architecture Overview

```
┌──────────┐       ┌──────────────┐       ┌─────────┐
│ Student  │──M:N──│ Project_Team │──M:N──│ Project │
└──────────┘       └──────────────┘       └────┬────┘
                                               │
                   ┌───────────────┐           │ 1:N
                   │ Project_Guide │───────────┤
                   └───────┬───────┘           │
                           │                   │ 1:N
                   ┌───────┴───────┐   ┌──────┴──────────┐
                   │   Faculty     │   │ Project_Progress │
                   └───────┬───────┘   └─────────────────┘
                           │
                   ┌───────┴────────┐       ┌─────────────┐
                   │  Coordinator   │──────│ Meeting_Log  │
                   └───────┬────────┘       └─────────────┘
                           │
                   ┌───────┴────────────────┐
                   │ Coordinator_Assignment  │
                   └─────────────────────────┘

        Project ↔ Project  (self-referencing via Collaboration)
```

## 🗂️ Entities (10 Tables)

1. **student** — Student personal details and academic info
2. **project** — Project details, type (application/research), timeline, and status
3. **faculty** — Faculty members with expertise and designation
4. **project_team** — Links students to projects with roles (team lead, developer, etc.)
5. **project_guide** — Faculty-to-project guide assignments
6. **coordinator** — Faculty members designated as project coordinators
7. **coordinator_assignment** — Coordinator-to-project oversight mappings
8. **meeting_log** — Meeting records with agenda, feedback, and action items
9. **project_progress** — Milestone tracking, progress updates, and challenges
10. **collaboration** — Inter-project collaborations (resource sharing, joint research)

## ⚙️ Key Design Decisions

- **One active project per student**: Enforced via a generated column + UNIQUE constraint on `project_team`
- **Faculty dual roles**: Faculty can simultaneously be a project guide AND a coordinator (separate tables)
- **Project types as ENUM**: `application` and `research` — easily extensible
- **Self-referencing M:N for collaboration**: `project_id_1 < project_id_2` check prevents duplicates
- **3NF normalization**: No redundant data; all transitive dependencies eliminated

## 🚀 Quick Start

```sql
-- Run in MySQL 8.0+
source schema.sql;

-- Verify tables
SHOW TABLES;

-- Check sample data
SELECT s.name, p.title, pt.role
FROM student s
JOIN project_team pt ON s.student_id = pt.student_id
JOIN project p ON pt.project_id = p.project_id
WHERE pt.is_active = 1;
```

## 🔮 Future Scalability

The schema supports extension for:
- **Document/file uploads** — Add a `project_documents` table with file metadata
- **Evaluation & grading** — Add `project_evaluation` linked to guides/coordinators
- **Notification system** — Add `notifications` table for deadline reminders
- **Department-level analytics** — Current `department` fields enable aggregation queries
