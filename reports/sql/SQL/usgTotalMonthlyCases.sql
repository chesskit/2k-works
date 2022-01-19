Select
  `Parts of USG Scanned`,
  `OPD/Ward`,
   Emergency,
  `Total No Of Cases Done`
FROM
  (
    SELECT
      1                                                        AS 'Ordering',
      AllUSGOrder.`Parts of USG Scanned`,
      ifnull(USGOrderFromOpdAndWard.`OPD/Ward`, 0)             AS 'OPD/Ward',
      ifnull(USGOrderFromEmergency.Emergency, 0)               AS 'Emergency',
      ifnull(TotalUSGForEachOrder.`Total No Of Cases Done`, 0) AS 'Total No Of Cases Done'
    FROM (
           /*List of all the USG order in the system*/
           SELECT cn.name AS 'Parts of USG Scanned'
           FROM concept_set cs
             JOIN
             concept_name cn
               ON cn.concept_id = cs.concept_id
           WHERE concept_set = (SELECT concept_id
                                FROM concept_name
                                WHERE name = 'USG' AND concept_name_type = 'FULLY_SPECIFIED')
                 AND cn.concept_name_type = 'SHORT'
           ORDER BY cn.name
         ) AllUSGOrder

      LEFT JOIN

      (
        /*Scans done for OPD and Ward visit*/
        SELECT
          cn.name                  AS 'Parts of USG Scanned',
          count(DISTINCT order_id) AS 'OPD/Ward'
        FROM orders o
          JOIN
          concept_name cn
            ON cn.concept_id = o.concept_id
          JOIN encounter e
            ON e.encounter_id = o.encounter_id
          JOIN visit v
            ON v.visit_id = e.visit_id
        WHERE o.voided IS FALSE
              AND o.order_type_id IN (SELECT order_type_id
                                      FROM order_type
                                      WHERE name = 'USG Order')
              AND date(o.date_created) BETWEEN '#startDate#' and '#endDate#'
              AND o.order_id NOT IN (SELECT previous_order_id
                                     FROM orders
                                     WHERE order_action = 'DISCONTINUE')
              AND cn.concept_name_type = 'SHORT'
              AND v.visit_type_id IN (SELECT visit_type_id
                                      FROM visit_type
                                      WHERE name <> 'Emergency')
        GROUP BY cn.name
      ) USGOrderFromOpdAndWard
        ON AllUSGOrder.`Parts of USG Scanned` = USGOrderFromOpdAndWard.`Parts of USG Scanned`

      LEFT JOIN

      (
        /*Scans done under emergency visit*/
        SELECT
          cn.name                  AS 'Parts of USG Scanned',
          count(DISTINCT order_id) AS 'Emergency'
        FROM orders o
          JOIN
          concept_name cn
            ON cn.concept_id = o.concept_id
          JOIN encounter e
            ON e.encounter_id = o.encounter_id
          JOIN visit v
            ON v.visit_id = e.visit_id
        WHERE o.voided IS FALSE
              AND o.order_type_id IN (SELECT order_type_id
                                      FROM order_type
                                      WHERE name = 'USG Order')
              AND date(o.date_created) BETWEEN '#startDate#' and '#endDate#'
              AND o.order_id NOT IN (SELECT previous_order_id
                                     FROM orders
                                     WHERE order_action = 'DISCONTINUE')
              AND cn.concept_name_type = 'SHORT'
              AND v.visit_type_id IN (SELECT visit_type_id
                                      FROM visit_type
                                      WHERE name = 'Emergency')
        GROUP BY cn.name
      ) USGOrderFromEmergency

        ON AllUSGOrder.`Parts of USG Scanned` = USGOrderFromEmergency.`Parts of USG Scanned`

      LEFT JOIN

      (
        /*Total cases for each USG order*/
        SELECT
          cn.name                  AS 'Parts of USG Scanned',
          count(DISTINCT order_id) AS 'Total No Of Cases Done'
        FROM orders o
          JOIN
          concept_name cn
            ON cn.concept_id = o.concept_id
        WHERE o.voided IS FALSE
              AND o.order_type_id IN (SELECT order_type_id
                                      FROM order_type
                                      WHERE name = 'USG Order')
              AND date(o.date_created) BETWEEN '#startDate#' and '#endDate#'
              AND o.order_id NOT IN (SELECT previous_order_id
                                     FROM orders
                                     WHERE order_action = 'DISCONTINUE')
              AND cn.concept_name_type = 'SHORT'
        GROUP BY cn.name
      ) TotalUSGForEachOrder
        ON AllUSGOrder.`Parts of USG Scanned` = TotalUSGForEachOrder.`Parts of USG Scanned`

    UNION ALL

    /*Grand total patient scanned*/
    SELECT
      2                             AS 'Ordering',
      'Grand Total Patient Scanned' AS 'Parts of USG Scanned',
      '-',
      '-',
      count(DISTINCT order_id)      AS 'Total No Of Cases Done'
    FROM orders o
      JOIN
      concept_name cn
        ON cn.concept_id = o.concept_id
    WHERE o.voided IS FALSE
          AND o.order_type_id IN (SELECT order_type_id
                                  FROM order_type
                                  WHERE name = 'USG Order')
          AND date(o.date_created) BETWEEN '#startDate#' and '#endDate#'
          AND o.order_id NOT IN (SELECT previous_order_id
                                 FROM orders
                                 WHERE order_action = 'DISCONTINUE')
          AND cn.concept_name_type = 'SHORT'
  )USGTotalCases
ORDER BY Ordering,`Parts of USG Scanned`;