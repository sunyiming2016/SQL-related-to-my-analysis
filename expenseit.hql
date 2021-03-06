---the code to test the company product adoption probability(defined by the percentage of users who used the expenseit at least once )

with a as 
(
select  user_id,
        sum(expenseit_entry_ct) as expenseit,  
        er.entity_id
from 
        t_ux.tbl_expense_report er join c_expense.site_setting ss on er.entity_id=ss.entity_id
where 
        mobile is not null and is_receipt_required='Y' and expenseit_enabled=1---select users from an expenseit enabled company who had mobile activities and receipt was required
group by 
        user_id,
        entity_id
)
,

b as 
(
select 
        entity_id,
        sum(case when expenseit=0 then 0 else 1 end) / count(*) as adoption_probability -- this returns the product adoption probability on the company level. 
from 
        a 
group by entity_id
)
select 
       avg(adoption_probability) as average_adoption,
       median (adoption_probability) as median_adoption
from b



---the code to test the retention rate(defined by the percentage of users who used expenseit at least once within the 3 months after using it for the first time)
with a as 
(
select 
        user_id,
        entity_id,
        min(submit_dttm) as first_date  -- first time of submitting a report with expenseit entries
from 
       t_ux.tbl_expense_report er join c_expense.site_setting ss on er.entity_id=ss.entity_id
where 
        mobile is not null and is_receipt_required='Y' and expenseit_entry_ct>0 and ss.expenseit_enabled=1
group by 
        user_id,
        entity_id
),
b as 
(
select 
        er.user_id,
        er.entity_id,
        sum(case when er.submit_dttm > first_date and er.submit_dttm<= dateadd( first_date, interval 3 months) then 1 else 0 end )as has_another  --whether an user did at least another expenseit report wihin 3 months after the first expenseit report
from
        t_ux.tbl_expense_report er join a on er.user_id=a.user_id and er.entity_id=a.entity_id join c_expense.site_setting ss on er.entity_id=ss.entity_id
where
        mobile is not null and is_receipt_required='Y' and expenseit_entry_ct>0 and ss.expenseit_enabled=1
group by 
        user_id,
        entity_id
)
,
c as 
(
select 
        entity_id,
        sum( case when has_another>0 then 1 else 0 end)/count(*) as retention  ---this returns the product retention rate on the company level
from b 
group by 
        entity_id
)
select avg(retention) as average_retention,
       median(retention) as median_retention
from c


