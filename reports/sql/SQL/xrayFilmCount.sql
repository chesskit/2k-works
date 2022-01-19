Select `X-ray film size`,
  `No of X-ray films exposed`
from (
  /*Count based on the film type*/
  SELECT

    CASE WHEN cn.name = "14''X17''"
      THEN 15
    WHEN cn.name = "12''X15''"
      THEN 16
    WHEN cn.name = "10''X12''"
      THEN 17
    ELSE 18
    END           AS 'Ordering',
    cn.name       AS 'X-ray film size',
    count(obs_id) AS 'No of X-ray films exposed'
  FROM obs obs
    JOIN concept_name cn
      ON obs.value_coded = cn.concept_id
  WHERE cn.name IN (
    "14''X17''",
    "12''X15''",
    "10''X12''"
  )
        AND DATE(obs.date_created) BETWEEN '#startDate#' and '#endDate#'
        AND obs.voided IS FALSE
  GROUP BY cn.name

  UNION ALL

  /*Total count of the films*/
  SELECT

    19              AS 'Ordering',
    'Total films exposed'   AS 'X-ray film size',
    count(obs.obs_id) AS 'No of X-ray films exposed'
  FROM obs obs
    JOIN concept_name cn
      ON obs.value_coded = cn.concept_id
  WHERE cn.name IN (
    "14''X17''",
    "12''X15''",
    "10''X12''"
  )
        AND DATE(obs.date_created) BETWEEN '#startDate#' and '#endDate#'
        AND obs.voided IS FALSE

) FilmCounts
ORDER BY Ordering;