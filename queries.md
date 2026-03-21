# Relational Algebra & SQL Queries

## Student Project Management System

> **Schema Tables:** `student`, `project`, `faculty`, `project_team`, `project_guide`, `coordinator`, `coordinator_assignment`, `meeting_log`, `project_progress`, `collaboration`

---

### Q1. Retrieve all students with their assigned project details

**Relational Algebra:**

```
π student.name, student.department, project.title, project.type, project.status, project_team.role (
    student ⨝ (student.student_id = project_team.student_id) project_team
            ⨝ (project_team.project_id = project.project_id) project
)
```

**SQL:**

```sql
SELECT s.name, s.department, p.title, p.type, p.status, pt.role
FROM student s
JOIN project_team pt ON s.student_id = pt.student_id
JOIN project p ON pt.project_id = p.project_id;
```

---

### Q2. List all ongoing projects with their guides

**Relational Algebra:**

```
π project.title, project.start_date, faculty.name, faculty.department (
    σ (project.status = 'active') (
        project ⨝ (project.project_id = project_guide.project_id) project_guide
                ⨝ (project_guide.faculty_id = faculty.faculty_id) faculty
    )
)
```

**SQL:**

```sql
SELECT p.title, p.start_date, f.name AS guide_name, f.department
FROM project p
JOIN project_guide pg ON p.project_id = pg.project_id
JOIN faculty f ON pg.faculty_id = f.faculty_id
WHERE p.status = 'active';
```

---

### Q3. Fetch all progress updates for a specific project

**Relational Algebra:**

```
π project.title, project_progress.update_date, project_progress.description, project_progress.milestone_title, project_progress.milestone_status, project_progress.challenges (
    σ (project.project_id = 1) (
        project ⨝ (project.project_id = project_progress.project_id) project_progress
    )
)
```

**SQL:**

```sql
SELECT p.title, pp.update_date, pp.description,
       pp.milestone_title, pp.milestone_status, pp.challenges
FROM project_progress pp
JOIN project p ON pp.project_id = p.project_id
WHERE p.project_id = 1;
```

---

### Q4. Display faculty members mentoring multiple projects

**Relational Algebra:**

```
π faculty.name, faculty.department (
    σ (project_count > 1) (
        faculty.name, faculty.department ɣ COUNT(project_guide.project_id) AS project_count (
            faculty ⨝ (faculty.faculty_id = project_guide.faculty_id) project_guide
        )
    )
)
```

**SQL:**

```sql
SELECT f.name, f.department, COUNT(pg.project_id) AS project_count
FROM faculty f
JOIN project_guide pg ON f.faculty_id = pg.faculty_id
GROUP BY f.faculty_id, f.name, f.department
HAVING COUNT(pg.project_id) > 1;
```

---

### Q5. List all projects that have collaborated with at least one other project

**Relational Algebra:**

```
π project.project_id, project.title, project.type (
    project ⨝ (project.project_id = collaboration.project_id_1) collaboration
)
∪
π project.project_id, project.title, project.type (
    project ⨝ (project.project_id = collaboration.project_id_2) collaboration
)
```

**SQL:**

```sql
SELECT DISTINCT p.project_id, p.title, p.type
FROM project p
WHERE p.project_id IN (
    SELECT project_id_1 FROM collaboration
    UNION
    SELECT project_id_2 FROM collaboration
);
```

---

### Q6. List students working on research-based projects

**Relational Algebra:**

```
π student.name, student.department, project.title (
    student ⨝ (student.student_id = project_team.student_id) project_team
            ⨝ (project_team.project_id = project.project_id) (σ (type = 'research') project)
)
```

**SQL:**

```sql
SELECT s.name, s.department, p.title
FROM student s
JOIN project_team pt ON s.student_id = pt.student_id
JOIN project p ON pt.project_id = p.project_id
WHERE p.type = 'research';
```

---

### Q7. Retrieve the latest progress update for each project

**Relational Algebra:**

```
π project.title, pp.update_date, pp.description, pp.milestone_title (
    project ⨝ (project.project_id = pp.project_id) (
        σ (pp.update_date = max_date) (
            project_progress AS pp
            ⨝ (pp.project_id = latest.project_id)
            ( project_id ɣ MAX(update_date) AS max_date (project_progress) ) AS latest
        )
    )
)
```

**SQL:**

```sql
SELECT p.title, pp.update_date, pp.description, pp.milestone_title
FROM project_progress pp
JOIN project p ON pp.project_id = p.project_id
WHERE pp.update_date = (
    SELECT MAX(pp2.update_date)
    FROM project_progress pp2
    WHERE pp2.project_id = pp.project_id
);
```

---

### Q8. Count the number of projects per project type

**Relational Algebra:**

```
type ɣ COUNT(project_id) AS project_count (project)
```

**SQL:**

```sql
SELECT type, COUNT(project_id) AS project_count
FROM project
GROUP BY type;
```

---

### Q9. Retrieve faculty guides along with the projects they are mentoring

**Relational Algebra:**

```
π faculty.name, faculty.department, project.title, project.status, project_guide.assigned_date (
    faculty ⨝ (faculty.faculty_id = project_guide.faculty_id) project_guide
            ⨝ (project_guide.project_id = project.project_id) project
)
```

**SQL:**

```sql
SELECT f.name, f.department, p.title, p.status, pg.assigned_date
FROM faculty f
JOIN project_guide pg ON f.faculty_id = pg.faculty_id
JOIN project p ON pg.project_id = p.project_id;
```

---

### Q10. List all faculty coordinators and the number of projects they are overseeing

**Relational Algebra:**

```
π faculty.name, faculty.department, project_count (
    faculty.name, faculty.department ɣ COUNT(coordinator_assignment.project_id) AS project_count (
        faculty ⨝ (faculty.faculty_id = coordinator.faculty_id) coordinator
                ⨝ (coordinator.coordinator_id = coordinator_assignment.coordinator_id) coordinator_assignment
    )
)
```

**SQL:**

```sql
SELECT f.name, f.department, COUNT(ca.project_id) AS project_count
FROM faculty f
JOIN coordinator c ON f.faculty_id = c.faculty_id
JOIN coordinator_assignment ca ON c.coordinator_id = ca.coordinator_id
GROUP BY f.faculty_id, f.name, f.department;
```

---

### Q11. Retrieve the names of all students supervised by a specific faculty guide

**Relational Algebra:**

```
π student.name, student.department, project.title (
    student ⨝ (student.student_id = project_team.student_id) project_team
            ⨝ (project_team.project_id = project_guide.project_id) (
                σ (faculty_id = 1) project_guide
            )
            ⨝ (project_team.project_id = project.project_id) project
)
```

**SQL:**

```sql
SELECT s.name, s.department, p.title
FROM student s
JOIN project_team pt ON s.student_id = pt.student_id
JOIN project_guide pg ON pt.project_id = pg.project_id
JOIN project p ON pt.project_id = p.project_id
WHERE pg.faculty_id = 1;   -- Replace 1 with desired faculty_id
```

---

### Q12. Display the total number of students participating in each project

**Relational Algebra:**

```
π project.title, student_count (
    project ⨝ (project.project_id = temp.project_id) (
        project_id ɣ COUNT(student_id) AS student_count (project_team)
    ) AS temp
)
```

**SQL:**

```sql
SELECT p.title, COUNT(pt.student_id) AS student_count
FROM project p
LEFT JOIN project_team pt ON p.project_id = pt.project_id
GROUP BY p.project_id, p.title;
```

---

### Q13. Retrieve all faculty guides and their expertise areas

**Relational Algebra:**

```
π faculty.name, faculty.expertise (
    faculty ⨝ (faculty.faculty_id = project_guide.faculty_id) project_guide
)
```

**SQL:**

```sql
SELECT DISTINCT f.name, f.expertise
FROM faculty f
JOIN project_guide pg ON f.faculty_id = pg.faculty_id;
```

---

### Q14. Retrieve all projects completed within a specific date range

**Relational Algebra:**

```
π project_id, title, start_date, end_date (
    σ (status = 'completed' ∧ end_date >= '2025-01-01' ∧ end_date <= '2026-12-31') (project)
)
```

**SQL:**

```sql
SELECT project_id, title, start_date, end_date
FROM project
WHERE status = 'completed'
  AND end_date BETWEEN '2025-01-01' AND '2026-12-31';
```

---

### Q15. Find the projects with no assigned students

**Relational Algebra:**

```
π project.project_id, project.title (
    project
) − π project.project_id, project.title (
    project ⨝ (project.project_id = project_team.project_id) project_team
)
```

**SQL:**

```sql
SELECT p.project_id, p.title
FROM project p
LEFT JOIN project_team pt ON p.project_id = pt.project_id
WHERE pt.student_id IS NULL;
```

---

### Q16. Retrieve the number of students per department working on projects

**Relational Algebra:**

```
department ɣ COUNT(student_id) AS student_count (
    π student.student_id, student.department (
        student ⨝ (student.student_id = project_team.student_id) project_team
    )
)
```

**SQL:**

```sql
SELECT s.department, COUNT(DISTINCT s.student_id) AS student_count
FROM student s
JOIN project_team pt ON s.student_id = pt.student_id
GROUP BY s.department;
```

---

### Q17. Retrieve all projects along with the number of progress updates

**Relational Algebra:**

```
π project.title, update_count (
    project ⟕ (project.project_id = temp.project_id) (
        project_id ɣ COUNT(progress_id) AS update_count (project_progress)
    ) AS temp
)
```

**SQL:**

```sql
SELECT p.title, COUNT(pp.progress_id) AS update_count
FROM project p
LEFT JOIN project_progress pp ON p.project_id = pp.project_id
GROUP BY p.project_id, p.title;
```

---

### Q18. Get the projects that have faced the most challenges based on progress updates

**Relational Algebra:**

```
π project.title, challenge_count (
    project ⨝ (project.project_id = temp.project_id) (
        project_id ɣ COUNT(progress_id) AS challenge_count (
            σ (challenges IS NOT NULL) (project_progress)
        )
    ) AS temp
)
-- then select tuples where challenge_count = MAX(challenge_count)
```

**SQL:**

```sql
SELECT p.title, COUNT(pp.progress_id) AS challenge_count
FROM project p
JOIN project_progress pp ON p.project_id = pp.project_id
WHERE pp.challenges IS NOT NULL
GROUP BY p.project_id, p.title
ORDER BY challenge_count DESC
LIMIT 1;
```

---

### Q19. List the faculty guides and their total number of assigned students

**Relational Algebra:**

```
π faculty.name, student_count (
    faculty.name ɣ COUNT(project_team.student_id) AS student_count (
        faculty ⨝ (faculty.faculty_id = project_guide.faculty_id) project_guide
                ⨝ (project_guide.project_id = project_team.project_id) project_team
    )
)
```

**SQL:**

```sql
SELECT f.name, COUNT(pt.student_id) AS student_count
FROM faculty f
JOIN project_guide pg ON f.faculty_id = pg.faculty_id
JOIN project_team pt ON pg.project_id = pt.project_id
GROUP BY f.faculty_id, f.name;
```

---

### Q20. Retrieve all faculty members who are not mentoring any projects

**Relational Algebra:**

```
π faculty.faculty_id, faculty.name, faculty.department (faculty)
−
π faculty.faculty_id, faculty.name, faculty.department (
    faculty ⨝ (faculty.faculty_id = project_guide.faculty_id) project_guide
)
```

**SQL:**

```sql
SELECT f.faculty_id, f.name, f.department
FROM faculty f
LEFT JOIN project_guide pg ON f.faculty_id = pg.faculty_id
WHERE pg.guide_id IS NULL;
```

---

### Q21. List all projects that have missed deadlines

**Relational Algebra:**

```
π project_id, title, end_date, status (
    σ (end_date < CURRENT_DATE ∧ status ≠ 'completed') (project)
)
```

**SQL:**

```sql
SELECT project_id, title, end_date, status
FROM project
WHERE end_date < CURDATE()
  AND status != 'completed';
```

---

### Q22. Retrieve all students who haven't been assigned a project

**Relational Algebra:**

```
π student.student_id, student.name, student.department (student)
−
π student.student_id, student.name, student.department (
    student ⨝ (student.student_id = project_team.student_id) project_team
)
```

**SQL:**

```sql
SELECT s.student_id, s.name, s.department
FROM student s
LEFT JOIN project_team pt ON s.student_id = pt.student_id
WHERE pt.team_id IS NULL;
```

---

### Q23. Find the project with the highest number of team members

**Relational Algebra:**

```
π project.title, member_count (
    project ⨝ (project.project_id = temp.project_id) (
        σ (member_count = MAX(member_count)) (
            project_id ɣ COUNT(student_id) AS member_count (project_team)
        )
    ) AS temp
)
```

**SQL:**

```sql
SELECT p.title, COUNT(pt.student_id) AS member_count
FROM project p
JOIN project_team pt ON p.project_id = pt.project_id
GROUP BY p.project_id, p.title
ORDER BY member_count DESC
LIMIT 1;
```

---

### Q24. Identify the top 3 faculty members mentoring the highest number of projects

**Relational Algebra:**

```
-- Select top 3 from:
π faculty.name, faculty.department, project_count (
    faculty.faculty_id, faculty.name, faculty.department ɣ COUNT(project_guide.project_id) AS project_count (
        faculty ⨝ (faculty.faculty_id = project_guide.faculty_id) project_guide
    )
)
-- ordered descending by project_count, limit 3
```

**SQL:**

```sql
SELECT f.name, f.department, COUNT(pg.project_id) AS project_count
FROM faculty f
JOIN project_guide pg ON f.faculty_id = pg.faculty_id
GROUP BY f.faculty_id, f.name, f.department
ORDER BY project_count DESC
LIMIT 3;
```

---

### Q25. Get the percentage of students involved in research-based projects vs application-based projects

**Relational Algebra:**

```
-- Let T = COUNT of all students in project_team
-- Let R = COUNT of students in research projects
-- Let A = COUNT of students in application projects

type ɣ COUNT(pt.student_id) AS count, (COUNT(pt.student_id) / T) * 100 AS percentage (
    project ⨝ (project.project_id = project_team.project_id) project_team AS pt
)
```

**SQL:**

```sql
SELECT p.type,
       COUNT(pt.student_id) AS student_count,
       ROUND(
           COUNT(pt.student_id) * 100.0
           / (SELECT COUNT(*) FROM project_team),
           2
       ) AS percentage
FROM project p
JOIN project_team pt ON p.project_id = pt.project_id
GROUP BY p.type;
```
