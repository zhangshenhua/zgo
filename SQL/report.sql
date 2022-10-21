drop view if EXISTS view_report;
create view view_report as
    select uid, count(*) as stones
    from zi
    group by uid
    ORDER BY stones DESC
    limit 100
;

select * from view_report;
