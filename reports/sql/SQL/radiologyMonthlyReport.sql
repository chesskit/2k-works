Select Days,
  Sum(C1) AS '1',
  Sum(C2) AS '2',
  Sum(C3) AS '3',
  Sum(C4) AS '4',
  Sum(C5)AS '5',
  Sum(C6) AS '6',
  Sum(C7)AS '7',
  Sum(C8)AS '8',
  Sum(C9)AS '9',
  Sum(C10)AS '10',
  Sum(C11)AS '11',
  Sum(C12)AS '12',
  Sum(C13)AS '13',
  Sum(C14)AS '14',
  Sum(C15)AS '15',
  Sum(C16)AS '16',
  Sum(C17)AS '17',
  Sum(C18)AS '18',
  Sum(C19)AS '19',
  Sum(C20)AS '20',
  Sum(C21)AS '21',
  Sum(C22)AS '22',
  Sum(C23)AS '23',
  Sum(C24)AS '24',
  Sum(C25)AS '25',
  Sum(C26)AS '26',
  Sum(C27)AS '27',
  Sum(C28)AS '28',
  Sum(C29)AS '29',
  Sum(C30)AS '30',
  Sum(C31)AS '31'
FROM (
       SELECT
         'No pts' AS 'Days',
         CASE WHEN EXTRACT(DAY FROM date_created) = 1
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C1',
         CASE WHEN EXTRACT(DAY FROM date_created) = 2
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C2',
         CASE WHEN EXTRACT(DAY FROM date_created) = 3
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C3',
         CASE WHEN EXTRACT(DAY FROM date_created) = 4
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C4',
         CASE WHEN EXTRACT(DAY FROM date_created) = 5
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C5',
         CASE WHEN EXTRACT(DAY FROM date_created) = 6
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C6',
         CASE WHEN EXTRACT(DAY FROM date_created) = 7
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C7',
         CASE WHEN EXTRACT(DAY FROM date_created) = 8
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C8',
         CASE WHEN EXTRACT(DAY FROM date_created) = 9
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C9',
         CASE WHEN EXTRACT(DAY FROM date_created) = 10
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C10',
         CASE WHEN EXTRACT(DAY FROM date_created) = 11
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C11',
         CASE WHEN EXTRACT(DAY FROM date_created) = 12
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C12',
         CASE WHEN EXTRACT(DAY FROM date_created) = 13
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C13',
         CASE WHEN EXTRACT(DAY FROM date_created) = 14
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C14',
         CASE WHEN EXTRACT(DAY FROM date_created) = 15
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C15',
         CASE WHEN EXTRACT(DAY FROM date_created) = 16
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C16',
         CASE WHEN EXTRACT(DAY FROM date_created) = 17
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C17',
         CASE WHEN EXTRACT(DAY FROM date_created) = 18
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C18',
         CASE WHEN EXTRACT(DAY FROM date_created) = 19
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C19',
         CASE WHEN EXTRACT(DAY FROM date_created) = 20
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C20',
         CASE WHEN EXTRACT(DAY FROM date_created) = 21
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C21',
         CASE WHEN EXTRACT(DAY FROM date_created) = 22
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C22',
         CASE WHEN EXTRACT(DAY FROM date_created) = 23
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C23',
         CASE WHEN EXTRACT(DAY FROM date_created) = 24
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C24',
         CASE WHEN EXTRACT(DAY FROM date_created) = 25
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C25',
         CASE WHEN EXTRACT(DAY FROM date_created) = 26
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C26',
         CASE WHEN EXTRACT(DAY FROM date_created) = 27
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C27',
         CASE WHEN EXTRACT(DAY FROM date_created) = 28
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C28',
         CASE WHEN EXTRACT(DAY FROM date_created) = 29
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C29',
         CASE WHEN EXTRACT(DAY FROM date_created) = 30
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C30',
         CASE WHEN EXTRACT(DAY FROM date_created) = 31
           THEN  count(DISTINCT patient_id)
         ELSE 0 END       AS 'C31'
       FROM orders
       where voided is FALSE
             and order_type_id in (Select order_type_id from order_type where name ='Radiology Order')
             and date(date_created) BETWEEN '#startDate#' and '#endDate#'
             and order_id not in (Select previous_order_id from orders where order_action='DISCONTINUE' )
             and order_action='NEW'
       GROUP BY DATE(date_created)
       ORDER BY EXTRACT(DAY FROM date_created)
     ) OrdersCount
group by Days;