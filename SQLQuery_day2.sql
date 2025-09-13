use Interview_prac;
-- 🔁 [CTEs & Recursion] — 10 Queries

-- 1. List employees with more than one training using a CTE.

with emp_training as (
select Employee_ID 
from training_and_development_data
group by Employee_ID
having count(Training_Program_Name) > 1
)
select * from emp_training;
-- 2. Use a CTE to calculate average training cost per department and filter only those above $500.

with trainingcost as (
  select e.DepartmentType, AVG(t.Training_Cost) as avg_training_cost
  from training_and_development_data t 
  right join employee_data e on t.Employee_ID = e.EmpID
  group by e.DepartmentType
  having AVG(t.Training_Cost) > 500
)
select * from trainingcost;
-- 3. Recursive CTE: Build a mock org chart showing reporting hierarchy using Supervisor field.

with recursive org_chart as (
    select EmpID, Supervisor, 0 as level
    from employee_data
    where Supervisor is null -- Top level employees (e.g., CEOs)
    union all
    select e.EmpID, e.Supervisor, oc.level + 1
    from employee_data e
    inner join org_chart oc on e.Supervisor = oc.EmpID
)
select * from org_chart;


-- 4. Use a CTE to calculate rolling average of employee performance score by department.

with average as (
select DepartmentType, AVG(Current_Employee_Rating) as average_performance
from employee_data
group by DepartmentType
)
select * from average;
-- 5. Create a CTE that assigns row numbers to trainings by each employee and picks the latest.

with num as (
select Training_Program_Name,Employee_ID,
row_number() over (partition by training_program_name order by Employee_ID)as number
from training_and_development_data
)
select * from num;
-- 6. Chain multiple CTEs: One for top performers, another to join with training data.

with top_performer as (
select e.EmpID, e.Current_Employee_Rating,t.Training_Program_Name,t.Training_Outcome,t.Training_Cost, 
rank() over (partition by t.training_program_name order by e.current_employee_rating desc) as rank
from employee_data e right join training_and_development_data t on e.EmpID = t.Employee_ID
)
select top 10 * from top_performer ;
-- 7. Use CTE to calculate average tenure of employees in departments with >20 members.

with tenure as (
select AVG(DATEDIFF(MONTH,startDate,GETDate())) as tenure,DepartmentType from employee_data group by DepartmentType
having count(departmentType)>20
)
select * from tenure;
-- 8. Use a CTE to calculate % of employees trained in each job function.
with percentage_emp as (
  select JobFunctionDescription, 
         (count(EmpID) * 100.0) / (select count(*) from employee_data) as emp_percentage
  from employee_data 
  group by JobFunctionDescription
)
select * from percentage_emp;

-- 9. Use a CTE to find top 3 trainers by training count.

with top_trainer as (
select Trainer, RANK() over (partition by trainer order by count(employee_id)) as ranking
from training_and_development_data
group by Trainer
)
select * from top_trainer ;
-- 10. Use a CTE to compare performance score before and after a training program.

with performance_comparison as (
    select e.EmpID, 
           e.Current_Employee_Rating as before_training,
           t.Training_Outcome,
           t.Training_Cost
    from employee_data e
    join training_and_development_data t on e.EmpID = t.Employee_ID
    where t.Training_Program_Name is not null
)
select EmpID, before_training, Training_Outcome
from performance_comparison
where Training_Outcome = 'Completed' -- Assuming we want to compare post-training only.


-- 🧠 [Views] — 10 Queries

-- 1. Create a view to show active employees with training count.
DROP VIEW IF EXISTS active;

create view active as
select e.EmpID, count(t.Training_Program_Name) as training_count
from employee_data e right join training_and_development_data t on e.EmpID = t.Employee_ID
where e.EmployeeStatus = 'Active'
group by e.EmpID;
select * from active;
-- 2. Create a view to show department-wise salary summary (if salary exists).

CREATE VIEW vw_department_salary_summary AS
SELECT 
    DepartmentType,
    PayZone,                     
    COUNT(*) AS Employee_Count
FROM employee_data
WHERE PayZone IS NOT NULL       
GROUP BY DepartmentType, PayZone;
select * from vw_department_salary_summary;
-- 3. Create a view for terminated employees in the last year with their termination type.

create view termination as
select	empid,TerminationType, exitdate
from employee_data
WHERE exitdate >= DATEADD(YEAR, -1, GETDATE())
  AND exitdate <= GETDATE();
select * from termination;
-- 4. Create a view for employee tenure and rank them department-wise.
DROP VIEW IF EXISTS tenure;
create view tenure as
select DATEDIFF(YEAR,StartDate,GETDATE()) as tenure,DepartmentType ,rank() over (partition by departmentType order by DATEDIFF(MONTH,StartDate,GETDATE())) as rank
from employee_data
group by DepartmentType,StartDate 

select * from tenure;
-- 5. Create a view combining employee + recruitment data for analysis of hired vs rejected.

create view emp_recruitment as
select r.Applicant_ID, r.Status, e.StartDate
from recruitment_data r
left join employee_data e on r.Applicant_ID = e.EmpID
where r.Status in ('rejected', 'offered');

select * from emp_recruitment;

-- 6. Create a view to find employees whose performance improved after training.

create view improved_performance as
select e.EmpID, 
       e.Current_Employee_Rating as before_training,
       t.Training_Outcome,
       e.Performance_Score as after_training
from employee_data e
join training_and_development_data t on e.EmpID = t.Employee_ID
where t.Training_Program_Name is not null and 
      e.Performance_Score > e.Current_Employee_Rating;

select * from improved_performance;


-- 7. View to show average training cost by state.

create view average_cost as
select e.State , avg(t.Training_Cost) as average_cost
from employee_data e right join training_and_development_data t on e.EmpID = t.Employee_ID 
group by state

select * from average_cost
-- 8. View for department-wise top 5 earners (based on Pay Zone/Salary field).

create view top_performer as
select EmpID , Current_Employee_Rating , DepartmentType
from employee_data
group by DepartmentType,EmpID,Current_Employee_Rating

select top 5 * from top_performer ;
-- 9. View to show employees on leave and their last training.

create view emp_status as
select e.EmployeeStatus , t.Training_Program_Name
from employee_data e right join training_and_development_data t on e.EmpID = t.Employee_ID
where e.EmployeeStatus = 'leave of Absence'
select * from emp_status
-- 10. View to show employees without any training but with low performance.
create view employee_with_no_training as
select e.EmpID, e.Performance_Score, t.Training_Program_Name
from employee_data e left join training_and_development_data t on e.EmpID = t.Employee_ID
where t.Training_Program_Name is null
select * from employee_with_no_training

-- 🧪 [Temp Tables] — 10 Queries

-- 1. Create a temp table with employee_id, department, and latest training outcome.

create table #training_outcome(
	employee_id int primary key ,department varchar(45),training_outcome varchar(45)
)
insert into #training_outcome (employee_id,department,training_outcome)
select e.EmpID,e.DepartmentType,t.Training_Outcome
from employee_data e right join training_and_development_data t on e.EmpID = t.Employee_ID
select * from #training_outcome
-- 2. Insert top 10 expensive training programs into a temp table and run analytics.

create table #expensive_training (
training_program varchar(50), training_cost decimal
)
insert into #expensive_training (training_program, training_cost )
select top 10 Training_Program_Name, Training_Cost from training_and_development_data
order by Training_Cost desc 
select * from #expensive_training

-- Average cost of top 10 programs
SELECT AVG(training_cost) AS avg_cost
FROM #expensive_training;

-- Most expensive training program
SELECT TOP 3 training_program, training_cost
FROM #expensive_training
ORDER BY training_cost DESC;

-- 3. Create a temp table to hold average tenure per department.
drop table #average_tenure;
create table #average_tenure ( empid int primary key,
avgerage_tenure int, department varchar(45)
)
insert into  #average_tenure ( empid,
avgerage_tenure, department
)
select empid,DATEDIFF(YEAR,StartDate,GETDATE()) as avgerage_tenure, DepartmentType
from employee_data
group by DepartmentType,StartDate,EmpID

select * from #average_tenure
-- 4. Load all training sessions from 2023 into a temp table and calculate total cost.
create table #total_cost (
  training_date date, 
  training_duration int, 
  training_cost decimal
);

insert into #total_cost (training_date, training_duration, training_cost)
select Training_Date, Training_Duration_Days, Training_Cost 
from training_and_development_data
where Training_Date >= '2023-01-01';

select SUM(training_cost) as total_training_cost from #total_cost;

-- 5. Use a temp table to compare recruitment desired salary vs actual employee classification.


create table #compare_salary (
empid int, desired_salary decimal, payzone varchar(45)
)
insert into #compare_salary (empid, desired_salary, payzone)
select e.EmpID,r.Desired_Salary, e.PayZone
from recruitment_data r right join employee_data e on r.Applicant_ID = e.EmpID
select * from #compare_salary
-- 6. Temp table to store top 10 departments by training cost.

create table #top_10 (department varchar(45), training_cost decimal)
insert into #top_10 (department, training_cost)
select top 10 e.DepartmentType,sum(t.Training_Cost) 
from employee_data e right join training_and_development_data t on e.EmpID = t.Employee_ID
group by e.DepartmentType
select * from #top_10
-- 7. Temp table to find training programs not conducted in the last 36 months.
create table #training_pro (dates date, training_program varchar(45));
insert into #training_pro (dates, training_program)
select Training_Date, Training_Program_Name 
from training_and_development_data
where Training_Date >= DATEADD(MONTH, -36, GETDATE());

select * from #training_pro;


-- 8. Temp table for duplicate employee records (if any).

--no duplicate

-- 9. Temp table to simulate a scenario where training cost is increased by 10%.

create table #new_cost (training_program varchar(45),old_cost decimal,cost decimal)
insert into #new_cost (training_program ,old_cost, cost)
select Training_Program_Name, training_cost, (Training_Cost)*1.10
from training_and_development_data
select * from #new_cost
-- 10. Temp table to find employees with more than 2 leaves (if leave data exists).

create table #absence (empid int , counts int)
insert into #absence(empid,counts)
SELECT EmpID, COUNT(*) AS leave_count
FROM employee_data
WHERE EmployeeStatus = 'leave of absence'
GROUP BY EmpID
HAVING COUNT(*) >= 2;

-- ⚙️ [Query Optimization & Performance] — 10 Queries

-- 1. Optimize a query to calculate department-wise training cost using indexes (conceptual).

CREATE INDEX idx_employee_department
ON employee_data(empid, departmentType);
create index idx_cost
on training_and_development_data(training_cost)

select DepartmentType , SUM(Training_Cost)
from employee_data e right join training_and_development_data t on e.EmpID = t.Employee_ID
group by DepartmentType
-- 2. Rewrite a subquery with JOIN to reduce computation time.



-- 3. Replace correlated subqueries with joins in a performance query.

-- 4. Add filters early (WHERE clause) before GROUP BY to reduce data.

-- 5. Minimize columns in SELECT and avoid SELECT * in views (best practices).

-- 6. Use EXISTS instead of IN where appropriate for recruitment dataset.

-- 7. Combine two CTEs into one query using JOIN.

-- 8. Use CROSS APPLY (if using SQL Server) to pull top training record per employee.

-- 9. Convert multi-level subqueries into CTE for readability and performance.

-- 10. Use appropriate data types in temp tables to speed up filtering.


-- 🧩 [Joins, Aggregations & Analytics Functions] — 10 Queries

-- 1. Find employees who attended trainings from more than 2 different trainers.

select Employee_ID, count(Trainer) as no_trainer
from training_and_development_data
group by Employee_ID
having COUNT(Trainer) > 2;

-- 2. Find departments with >50% employees having excellent ratings.
SELECT DepartmentType, 
       (COUNT(CASE WHEN Performance_Score = 'exceed' THEN 1 END) * 1.0 / COUNT(EmpID)) * 100 AS PercentageExceed
FROM employee_data
GROUP BY DepartmentType
HAVING (COUNT(CASE WHEN Performance_Score = 'exceed' THEN 1 END) * 1.0 / COUNT(EmpID)) * 100 > 50;

-- 3. Compare average performance of zoneA vs zoneB employees.

SELECT PayZone, AVG(Current_Employee_Rating) AS Avg_Performance
FROM employee_data
WHERE PayZone IN ('zone A', 'zone B','zone C')
GROUP BY PayZone;

-- 4. Use RANK() to get top 3 performers per department.
WITH RankedEmployees AS (
    SELECT 
        EmpID, 
        DepartmentType, 
        Current_Employee_Rating,
        RANK() OVER (PARTITION BY DepartmentType ORDER BY Current_Employee_Rating DESC) as ranking
    FROM employee_data
)
select EmpID, DepartmentType, Current_Employee_Rating
from RankedEmployees
where ranking <= 3;



-- 5. Use DENSE_RANK() to analyze salaries by job function.

with salary_rank as (
select JobFunctionDescription, DENSE_RANK() over (partition by JobFunctionDescription order by Current_Employee_Rating) as emp_ranking
from employee_data
)
select * from salary_rank
-- 6. Partition by state to calculate average tenure using window function.

with avg_tenure as(
select State, AVG(DATEDIFF(YEAR,StartDate,GETDATE())) as average_tenure 
from employee_data
group by State
)
select * from avg_tenure
-- 7. List training programs where more than 5 employees participated.

select Employee_ID, Training_Program_Name 
from training_and_development_data group by training_program_name,Employee_ID
having count(Training_Program_Name) >=5

-- 8. Identify duplicate training entries (if any).

--no

-- 9. Get 2nd highest training cost per department using subquery or window.

with highest2nd as (
select DepartmentType, RANK() over (partition by DepartmentType order by training_cost) as ranking, Training_Cost 
from employee_data e right join training_and_development_data t on e.EmpID = t.Employee_ID 
group by DepartmentType,training_cost
)
select * from highest2nd where ranking = 2 
-- 10. Department-wise count of rejected applicants from recruitment data.

select DepartmentType , COUNT(*) as rejected
from employee_data e right join recruitment_data r on e.EmpID = r.Applicant_ID
where Status= 'rejected'
group by DepartmentType
-- 🎯 [Real-life Problem Solving] — 10 Queries

-- 1. Build a dashboard view combining employee + training + recruitment.

-- 2. Find mismatches in job title vs function (e.g., “HR Manager” in “Finance”).

-- 3. Find top 5 trainers whose trainees had best performance improvements.

-- 4. Show performance trend of employees before/after training (use dummy logic).

-- 5. Rank departments by average training cost + tenure combined.

-- 6. Show departments where high training cost did not lead to high performance.

-- 7. Identify employees with quick exit (less than 3 months of joining).

-- 8. Identify employees hired with desired salary >$70k but later terminated.

-- 9. List trainings costing >$1000 but given to employees with <3 rating.

-- 10. Create a mock bonus payout by joining performance + training participation.
