Select
`Parts to be done`,
  `No of cases`
FROM (
  /*Radiology order count based on the type*/
  SELECT
    CASE WHEN cn.name = 'Chest'
      THEN 1
    WHEN cn.name = 'Upper Extremeties'
      THEN 2
    WHEN cn.name = 'Lower Extremeties'
      THEN 3
    WHEN cn.name = 'Abdomen'
      THEN 4
    WHEN cn.name = 'Spine'
      THEN 5
    WHEN cn.name = 'PNS'
      THEN 6
    WHEN cn.name = 'Skull'
      THEN 7
    WHEN cn.name = 'Pelvis'
      THEN 8
    WHEN cn.name = 'KUB'
      THEN 9
    WHEN cn.name = 'Neck'
      THEN 10
    WHEN cn.name = 'Facial Bone'
      THEN 11
    WHEN cn.name = 'Hip Joints'
      THEN 12
    ELSE 13
    END
                     AS 'Ordering',
    CASE WHEN cn.name = 'Chest'
      THEN 'Chest/Lungs'
    ELSE cn.name END AS 'Parts to be done',
    count(order_id)  AS 'No of cases'
  FROM
    orders o
    JOIN
    concept_set cs
      ON o.concept_id = cs.concept_id
    JOIN
    concept_name cn
      ON cn.concept_id = cs.concept_set
  WHERE cs.concept_set <> (SELECT concept_id
                           FROM concept_name
                           WHERE name = 'Radiology' AND concept_name_type = 'FULLY_SPECIFIED')
        AND cn.concept_name_type = 'FULLY_SPECIFIED'
        AND o.voided IS FALSE
        AND o.order_type_id IN (SELECT order_type_id
                                FROM order_type
                                WHERE name = 'Radiology Order')
        AND date(o.date_created) BETWEEN '#startDate#' and '#endDate#'
        AND o.order_id NOT IN (SELECT previous_order_id
                               FROM orders
                               WHERE order_action = 'DISCONTINUE')
        AND o.order_action = 'NEW'
  GROUP BY cn.name

  UNION ALL


  /*Total radiology orders*/
  SELECT
    14            AS 'Ordering',
    'Total cases'   AS 'Parts to be done',
    count(order_id) AS 'No of cases'
  FROM
    orders o
    JOIN
    concept_set cs
      ON o.concept_id = cs.concept_id
    JOIN
    concept_name cn
      ON cn.concept_id = cs.concept_set
  WHERE cs.concept_set <> (SELECT concept_id
                           FROM concept_name
                           WHERE name = 'Radiology' AND concept_name_type = 'FULLY_SPECIFIED')
        AND cn.concept_name_type = 'FULLY_SPECIFIED'
        AND o.voided IS FALSE
        AND o.order_type_id IN (SELECT order_type_id
                                FROM order_type
                                WHERE name = 'Radiology Order')
        AND date(o.date_created) BETWEEN '#startDate#' and '#endDate#'
        AND o.order_id NOT IN (SELECT previous_order_id
                               FROM orders
                               WHERE order_action = 'DISCONTINUE')
        AND o.order_action = 'NEW'


) RadioOrders
 ORDER BY Ordering;