use Interview_prac;
-- =========================
-- Basic Level SQL Questions
-- =========================

-- 1. List all employees with their name, department, and job title.
-- Use: Employee Data → First Name, Last Name, Business Unit, Title

select FirstName,LastName,DepartmentType,JobFunctionDescription from employee_data;

-- 2. Get the details of employees who are currently on leave.
-- Use: Employee Data → Filter where Employee Status = 'Leave'

select FirstName,LastName from employee_data where EmployeeStatus='Leave of Absence';

-- 3. Find the number of employees in each department.
-- Use: GROUP BY Business Unit or Department Type

select DepartmentType, count(EmpID) from employee_data group by DepartmentType order by 2 desc;

-- 4. Retrieve a list of all employees who joined after a specific date (e.g., January 1, 2019).
-- Use: Filter on Start Date > '2019-01-01'

select EmpID, FirstName,LastName,StartDate from employee_data where StartDate >= '01-jan-19';

-- 5. Get the average salary of employees in each department.
-- Use: May infer salary from Pay Zone or Employee Classification Type if actual salary is missing

select count(empid) as no_emp,EmployeeType from employee_data group by EmployeeType; 

-- ============================
-- Intermediate Level SQL Questions
-- ============================

-- 6. List the employees who participated in training programs of a specific type (e.g., Technical).
-- Use: JOIN Employee Data with Training/Development Data → Filter by Training Type = 'Technical'

EXEC sp_rename 'dbo.training_and_development_data.[Training Program Name]', 'Training_Program_Name', 'COLUMN';

select e.FirstName, e.LastName, t.Training_Program_Name 
from employee_data e right join training_and_development_data t on e.empid = t.Employee_ID where t.Training_Program_Name = 'technical skills';

-- 7. Find the department with the highest average performance score.
-- Use: GROUP BY Department Type, then ORDER BY AVG(Performance Score) DESC

select DepartmentType,avg(Current_Employee_Rating) as avg_emp_rating from employee_data group by DepartmentType order by 2 desc;

-- 8. Retrieve a list of employees who haven't completed any training programs.
-- Use: LEFT JOIN Employee Data with Training Data → WHERE Training fields IS NULL

select e.EmpID, e.FirstName,e.LastName,t.Training_Program_Name 
from employee_data e left join training_and_development_data t on e.EmpID = t.Employee_ID 
where Training_Program_Name is null;

-- 9. Show all employees and their supervisor’s name.
-- Use: Employee Data → Self JOIN on Supervisor field (if Supervisor stores another Employee ID or name)

select e.empid, e.FirstName,e.LastName,s.Supervisor from employee_data e inner join employee_data s on e.EmpID=s.EmpID;

-- 10. Get the total number of training programs conducted by each trainer.
-- Use: Training Data → GROUP BY Trainer

select Trainer, count(Employee_ID) as total_training_programs from training_and_development_data group by Trainer order by 2 desc;

-- =========================
-- Advanced Level SQL Questions
-- =========================

-- 11. Find employees who have been assigned multiple supervisors.
-- Use: GROUP BY Employee ID → HAVING COUNT(DISTINCT Supervisor) > 1

select EmpID from employee_data group by EmpID having COUNT(distinct supervisor) > 1;

-- 12. Retrieve the list of departments where the average employee age is greater than a specified age (e.g., 40).
-- Use: Calculate age from DOB, GROUP BY Department → HAVING AVG(age) > 40

select DepartmentType, AVG(datediff(year,DOB, getdate())) as age from employee_data group by DepartmentType
having AVG(datediff(year,DOB, getdate())) >40;

-- 13. Show all employees with their corresponding recruitment status.
-- Use: JOIN Employee Data with Recruitment Data on Employee ID

select e.EmpID,e.FirstName,e.LastName, r.status from employee_data e right join recruitment_data r on e.EmpID = r.Applicant_ID;

-- 14. For each department, show the highest and lowest salary.
-- Use: GROUP BY Department Type → Use MAX() and MIN() on Pay Zone/Salary field

select e.departmentType, min(t.Training_Cost) as min_cost , max(t.Training_Cost) as max_cost
from training_and_development_data t right join employee_data e on e.EmpID = t.Employee_ID
group by departmentType;

-- 15. Find the percentage of employees with a performance score of 'Excellent' in each department.
-- Use: COUNT with FILTER → Divide by total in department and multiply by 100
SELECT 
  DepartmentType,
  COUNT(CASE WHEN [Performance_Score] = 'Exceeds' THEN 1 END) * 100.0 / COUNT(*) AS percentage_exceeds
FROM employee_data
GROUP BY DepartmentType;

-- ========================
-- Expert Level SQL Questions
-- ========================

-- 16. Rank employees in each department by their total training cost and display their rank.
-- Requires JOIN between employee_data and training_and_development_data
-- Use: SUM(training cost) per employee, then rank within each department

SELECT e.EmpID, e.DepartmentType, SUM(t.Training_Cost) AS Total_cost,
RANK() OVER (PARTITION BY e.DepartmentType ORDER BY SUM(t.Training_Cost) DESC) AS Training_Rank
FROM employee_data e 
JOIN training_and_development_data t ON e.EmpID = t.Employee_ID
GROUP BY e.EmpID, e.DepartmentType

-- 17. List employees who have participated in at least one training program and their corresponding outcomes.
-- Use: JOIN Employee Data with Training Data → Include Training Outcome field

select e.EmpID, t.Training_Outcome, t.Training_Program_Name 
from employee_data e right join training_and_development_data t on e.EmpID=t.Employee_ID where t.Training_Program_Name is not null ;

-- 18. Find the number of employees who were terminated within the last 6 months and their termination types.
-- Use: Filter Exit Date >= CURRENT_DATE - INTERVAL '6 MONTHS' → GROUP BY Termination Type

select TerminationType,COUNT(*) as terminated_employees
from employee_data where ExitDate >= DATEADD(MONTH,-6,GETDATE())
group by TerminationType;

-- 19. Identify departments with more than 10 employees who have a performance score of 'Needs Improvement'.
-- Use: WHERE Performance Score = 'Needs Improvement' → GROUP BY Department → HAVING COUNT(*) > 10

SELECT DepartmentType, COUNT(*) AS Low_Performance_Count
FROM employee_data
WHERE Performance_Score = 'Needs Improvement'
GROUP BY DepartmentType
HAVING COUNT(*) > 10;


-- 20. Using a window function, calculate the running total of training costs per employee.
-- Use: SUM(Training Cost) OVER (PARTITION BY Employee ID ORDER BY Training Date)

select Employee_ID,Training_Date, sum(Training_Cost) over (partition by employee_id order by training_date) from training_and_development_data;

-- =======================
-- Master Level SQL Questions
-- =======================

-- 21. Combine employee, training, and recruitment data to show the average number of training days per job function, ordered by total training cost.
-- Use: Multiple JOINs → GROUP BY Job Function → AVG(training days), SUM(training cost)

select e.JobFunctionDescription,avg(t.Training_Duration_Days) as avg_days, sum(t.Training_Cost) as total_cost
from employee_data e right join training_and_development_data t on e.empid = t.Employee_ID 
group by e.JobFunctionDescription order by sum(t.Training_Cost);
;

-- 22. Calculate average performance score for employees who applied for positions with a desired salary > $70,000, grouped by education level.
-- Use: JOIN Employee and Recruitment Data → WHERE Desired Salary > 70000 → GROUP BY Education Level

select avg(e.Current_Employee_Rating) as avg_rating, r.education_level from employee_data e right join recruitment_data r on e.EmpID = r.Applicant_ID where Desired_Salary > 70000
group by r.Education_Level;

-- 23. Find the most common termination reason across all departments.
-- Use: GROUP BY Termination Description → ORDER BY COUNT(*) DESC → LIMIT 1

select TerminationDescription from employee_data GROUP BY TerminationDescription order by count(*) desc limit 1; --mysqk=l

SELECT TOP 1 TerminationDescription
FROM employee_data
GROUP BY TerminationDescription
ORDER BY COUNT(*) DESC;


-- 24. For each state, calculate the average time an employee stays in the company (Exit Date - Start Date).
-- Use: DATEDIFF or DATE_PART on Exit Date - Start Date → GROUP BY State

select state, AVG(datediff(DAY,StartDate, getdate())) as avg_days_of_working from employee_data group by State; 

-- 25. Use a CTE to calculate the top 5 employees with the most absences in the last year.
-- Use: CTE with Absence Data → Filter by last year → ORDER BY total absences DESC → LIMIT 5
WITH top_5_emp AS (
    SELECT EmpID, Current_Employee_Rating
    FROM employee_data
)
SELECT TOP 5 *
FROM top_5_emp
ORDER BY Current_Employee_Rating;