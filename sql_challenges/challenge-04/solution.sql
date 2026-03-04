-- Analytic Functions: Databases for Developers

-- 3 . Try it!
-- Complete the following query to return the count and average weight of bricks for each shape:

select b.*,
      count(*) over (
        partition by shape
      ) bricks_per_shape,
      median ( weight ) over (
        partition by weight
      ) median_weight_per_shape
from   bricks b
order  by shape, weight, brick_id;


-- 5 . Try it!
-- Complete the following query to get the running average weight, ordered by brick_id:

select b.brick_id, b.weight,
      round ( avg ( weight ) over (
        order by brick_id
      ), 2 ) running_average_weight
from   bricks b
order  by brick_id;


--9 . Try It!
--Complete the windowing clauses to return:
--* The minimum colour of the two rows before (but not including) the current row
--* The count of rows with the same weight as the current and one value following

select b.*,
      min ( colour ) over (
        order by brick_id
        rows between 2 preceding and 1 preceding
      ) first_colour_two_prev,
      count (*) over (
        order by weight
        range between current row and 1 following
      ) count_values_this_and_next
from   bricks b
order  by weight;


-- 11 . Try It!
-- Complete the following query to find the rows where
-- * The total weight for the shape
-- * The running weight by brick_id
--   are both greater than four:

with totals as (
 select b.*,
        sum ( weight ) over (
          partition by shape
        ) weight_per_shape,
        sum ( weight ) over (
          order by brick_id
        ) running_weight_by_id
 from   bricks b
)
select * from totals
where  weight_per_shape > 4 and running_weight_by_id > 4;
order  by brick_id


-- Top Three Salaries - FAANG SQL Interview Question
with ranked as (
  SELECT 
    d.department_name,
    e.name,
    e.salary,
    dense_rank() over (
      partition by e.department_id
      order by e.salary DESC
    ) AS rnk
  FROM employee e 
  JOIN department d
    ON e.department_id = d.department_id
)

SELECT department_name, name, salary FROM ranked
WHERE rnk <=3
ORDER BY 
  department_name ASC,
  salary DESC,
  name ASC;
