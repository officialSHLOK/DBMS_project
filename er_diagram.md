# Conceptual Schema — ER Diagram

## Student Project Management System

This ER diagram represents all entities, attributes, and relationships for the student project management database.

```mermaid
erDiagram

    STUDENT {
        int student_id PK
        varchar name
        varchar email
        varchar phone
        varchar department
        int year_of_study
        int enrollment_year
    }

    PROJECT {
        int project_id PK
        varchar title
        text description
        enum type "application | research"
        date start_date
        date end_date
        enum status "proposed | active | completed | on_hold"
    }

    FACULTY {
        int faculty_id PK
        varchar name
        varchar email
        varchar department
        varchar designation
        varchar expertise
    }

    PROJECT_TEAM {
        int team_id PK
        int student_id FK
        int project_id FK
        varchar role "team_lead | developer | researcher | tester | designer"
        date joined_date
        tinyint is_active
    }

    PROJECT_GUIDE {
        int guide_id PK
        int faculty_id FK
        int project_id FK
        date assigned_date
        tinyint is_active
    }

    COORDINATOR {
        int coordinator_id PK
        int faculty_id FK
        date appointed_date
        tinyint is_active
    }

    COORDINATOR_ASSIGNMENT {
        int assignment_id PK
        int coordinator_id FK
        int project_id FK
        date assigned_date
    }

    MEETING_LOG {
        int meeting_id PK
        int coordinator_id FK
        int project_id FK
        date meeting_date
        varchar agenda
        text feedback
        text action_items
    }

    PROJECT_PROGRESS {
        int progress_id PK
        int project_id FK
        date update_date
        text description
        varchar milestone_title
        enum milestone_status "pending | in_progress | completed"
        text challenges
    }

    COLLABORATION {
        int collaboration_id PK
        int project_id_1 FK
        int project_id_2 FK
        enum collab_type "resource_sharing | joint_research | joint_development"
        text description
        date start_date
        date end_date
    }

    %% ---- Relationships ----

    STUDENT ||--o{ PROJECT_TEAM : "participates in"
    PROJECT ||--o{ PROJECT_TEAM : "has members"

    FACULTY ||--o{ PROJECT_GUIDE : "guides"
    PROJECT ||--o{ PROJECT_GUIDE : "supervised by"

    FACULTY ||--o| COORDINATOR : "may serve as"
    COORDINATOR ||--o{ COORDINATOR_ASSIGNMENT : "oversees"
    PROJECT ||--o{ COORDINATOR_ASSIGNMENT : "monitored by"

    COORDINATOR ||--o{ MEETING_LOG : "conducts"
    PROJECT ||--o{ MEETING_LOG : "discussed in"

    PROJECT ||--o{ PROJECT_PROGRESS : "has updates"

    PROJECT ||--o{ COLLABORATION : "collaborates (as project 1)"
    PROJECT ||--o{ COLLABORATION : "collaborates (as project 2)"
```

---

## Entity Descriptions

| Entity | Description |
|---|---|
| **Student** | Undergraduate engineering student enrolled in the program |
| **Project** | A project undertaken by a team — either application-based or research-based |
| **Faculty** | Faculty members who can serve as guides or coordinators |
| **Project Team** | Associative entity linking students to projects with designated roles |
| **Project Guide** | Associative entity mapping faculty to projects they supervise |
| **Coordinator** | A subset of faculty serving as project coordinators |
| **Coordinator Assignment** | Links coordinators to the projects they monitor |
| **Meeting Log** | Records of meetings conducted by coordinators for each project |
| **Project Progress** | Tracks milestones, updates, and challenges for each project |
| **Collaboration** | Captures inter-project collaborations (resource sharing, joint work) |

---

## Key Relationship Rules

1. **Student → Project**: Many-to-Many via `PROJECT_TEAM`, but constrained so a student can only be in **one active project** at a time (`is_active = 1` unique constraint).
2. **Faculty → Project (as Guide)**: Many-to-Many via `PROJECT_GUIDE` — a faculty member can guide multiple projects.
3. **Faculty → Coordinator**: One-to-One optional — only some faculty serve as coordinators.
4. **Coordinator → Project**: Many-to-Many via `COORDINATOR_ASSIGNMENT`.
5. **Project ↔ Project**: Self-referencing Many-to-Many via `COLLABORATION`.
6. **Project → Progress**: One-to-Many — each project has multiple progress entries.
7. **Coordinator + Project → Meeting Log**: One-to-Many — multiple meetings per coordinator-project pair.
