---1---
Посчитайте, сколько компаний закрылось.

SELECT COUNT(id)
FROM company
WHERE status = 'closed'

---2---
Отобразите количество привлечённых средств для новостных компаний США. Используйте данные из таблицы company. Отсортируйте таблицу по убыванию значений в поле funding_total.

SELECT funding_total
FROM company
WHERE category_code = 'news'
AND country_code = 'USA'
ORDER BY funding_total DESC

---3---
Найдите общую сумму сделок по покупке одних компаний другими в долларах. Отберите сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно.

SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash'
AND EXTRACT(year FROM acquired_at) BETWEEN 2011 AND 2013

---4---
Отобразите имя, фамилию и названия аккаунтов людей в твиттере, у которых названия аккаунтов начинаются на 'Silver'.

SELECT first_name,
       last_name,
       twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%'

---5---
Выведите на экран всю информацию о людях, у которых названия аккаунтов в твиттере содержат подстроку 'money', а фамилия начинается на 'K'.

SELECT *
FROM people
WHERE twitter_username LIKE '%money%'
AND last_name LIKE 'K%'

---6---
Для каждой страны отобразите общую сумму привлечённых инвестиций, которые получили компании, зарегистрированные в этой стране. Страну, в которой зарегистрирована компания, можно определить по коду страны. Отсортируйте данные по убыванию суммы.

SELECT country_code,
       SUM(funding_total)
FROM company
GROUP BY country_code
ORDER BY SUM(funding_total) DESC

---7---
Составьте таблицу, в которую войдёт дата проведения раунда, а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
Оставьте в итоговой таблице только те записи, в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению.

SELECT *
FROM (SELECT funded_at,
             MIN(raised_amount),
             MAX(raised_amount)
     FROM funding_round
     GROUP BY funded_at) AS a
WHERE min != 0
AND min != max

---8---
Создайте поле с категориями:
Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию high_activity.
Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию middle_activity.
Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию low_activity.
Отобразите все поля таблицы fund и новое поле с категориями.

SELECT CASE
           WHEN invested_companies >= 100 THEN 'high_activity'
           WHEN invested_companies >= 20 THEN 'middle_activity'
           WHEN invested_companies < 20 THEN 'low_activity'
       END,
       *
FROM fund

---9---
Для каждой из категорий, назначенных в предыдущем задании, посчитайте округлённое до ближайшего целого числа среднее количество инвестиционных раундов, в которых фонд принимал участие. Выведите на экран категории и среднее число инвестиционных раундов. Отсортируйте таблицу по возрастанию среднего.

SELECT activity,
       ROUND(AVG(investment_rounds))
FROM (SELECT *,
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity
      FROM fund) AS b
GROUP BY activity
ORDER BY ROUND(AVG(investment_rounds))

---10---
Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
Для каждой страны посчитайте минимальное, максимальное и среднее число компаний, в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно. Исключите страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю. 
Выгрузите десять самых активных стран-инвесторов: отсортируйте таблицу по среднему количеству компаний от большего к меньшему. Затем добавьте сортировку по коду страны в лексикографическом порядке.

SELECT *
FROM (SELECT country_code,
           MIN(invested_companies),
           MAX(invested_companies),
           AVG(invested_companies)
      FROM fund
      WHERE EXTRACT(year FROM founded_at) BETWEEN 2010 AND 2012
      GROUP BY country_code) AS b
WHERE min != 0
ORDER BY avg DESC, country_code
LIMIT 10

---11---
Отобразите имя и фамилию всех сотрудников стартапов. Добавьте поле с названием учебного заведения, которое окончил сотрудник, если эта информация известна.

SELECT first_name,
       last_name,
       instituition
FROM people AS p 
LEFT OUTER JOIN education AS e ON p.id = e.person_id

---12---
Для каждой компании найдите количество учебных заведений, которые окончили её сотрудники. Выведите название компании и число уникальных названий учебных заведений. Составьте топ-5 компаний по количеству университетов.

SELECT c.name,
       COUNT(DISTINCT instituition)
FROM company AS c
INNER JOIN people AS p ON p.company_id = c.id
INNER JOIN education AS ed ON p.id = ed.person_id
GROUP BY c.name
ORDER BY COUNT(instituition) DESC
LIMIT 5

---13---
Составьте список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним.

SELECT name
FROM (SELECT *
FROM (SELECT *
      FROM company AS c
      WHERE status = 'closed') AS c
LEFT OUTER JOIN funding_round AS p ON c.id = p.company_id) AS new
WHERE is_first_round = 1
AND is_last_round = 1
GROUP BY name

---14---
Составьте список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании.

SELECT DISTINCT id
FROM people AS p
WHERE company_id IN (SELECT c.id
                    FROM company AS c
                    INNER JOIN funding_round AS fr ON c.id = fr.company_id
                    WHERE status = 'closed'
                    AND is_first_round = is_last_round
                    AND is_first_round = 1)

---15---
Составьте таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи и учебным заведением, которое окончил сотрудник.

WITH
op AS (SELECT DISTINCT id
FROM people AS p
WHERE company_id IN (SELECT c.id
                    FROM company AS c
                    INNER JOIN funding_round AS fr ON c.id = fr.company_id
                    WHERE status = 'closed'
                    AND is_first_round = is_last_round
                    AND is_first_round = 1))

SELECT p.id,
       ed.instituition
FROM people AS p
INNER JOIN education AS ed ON p.id = ed.person_id
WHERE company_id IN (SELECT c.id
                    FROM company AS c
                    INNER JOIN funding_round AS fr ON c.id = fr.company_id
                    WHERE status = 'closed'
                    AND is_first_round = is_last_round
                    AND is_first_round = 1)
GROUP BY p.id, ed.instituition


---16---
Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания. При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды.

SELECT p.id,
       COUNT(ed.instituition)
FROM people AS p
INNER JOIN education AS ed ON p.id = ed.person_id
WHERE company_id IN (SELECT c.id
                    FROM company AS c
                    INNER JOIN funding_round AS fr ON c.id = fr.company_id
                    WHERE status = 'closed'
                    AND is_first_round = is_last_round
                    AND is_first_round = 1)
GROUP BY p.id

---17---
Дополните предыдущий запрос и выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники разных компаний. Нужно вывести только одну запись, группировка здесь не понадобится.

SELECT AVG(count)
FROM (SELECT COUNT(ed.instituition)
FROM people AS p
INNER JOIN education AS ed ON p.id = ed.person_id
WHERE company_id IN (SELECT c.id
                    FROM company AS c
                    INNER JOIN funding_round AS fr ON c.id = fr.company_id
                    WHERE status = 'closed'
                    AND is_first_round = is_last_round
                    AND is_first_round = 1)
GROUP BY p.id) AS op

---18---
Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Facebook.

WITH
i AS (SELECT COUNT(instituition) AS avg_instituition, person_id
     FROM education
     GROUP BY person_id),
w AS (SELECT company_id, id
     FROM people),
q AS (SELECT name, id
     FROM company
     WHERE name = 'Facebook')
SELECT AVG(i.avg_instituition)
FROM i INNER JOIN w ON i.person_id = w.id
INNER JOIN q ON w.company_id = q.id

---19---
Составьте таблицу из полей:
name_of_fund — название фонда;
name_of_company — название компании;
amount — сумма инвестиций, которую привлекла компания в раунде.
В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, а раунды финансирования проходили с 2012 по 2013 год включительно.

SELECT f.name AS name_of_fund,
       c.name AS name_of_company,
       fr.raised_amount AS amount
FROM investment AS i
JOIN fund AS f ON i.fund_id = f.id
JOIN funding_round AS fr ON i.funding_round_id = fr.id
JOIN company AS c ON fr.company_id = c.id
WHERE c.milestones > 6
AND EXTRACT (year FROM funded_at) IN (2012, 2013)

---20---
Выгрузите таблицу, в которой будут такие поля:
название компании-покупателя;
сумма сделки;
название компании, которую купили;
сумма инвестиций, вложенных в купленную компанию;
доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.
Не учитывайте те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы. 
Отсортируйте таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании в лексикографическом порядке. Ограничьте таблицу первыми десятью записями.

SELECT c.name,
       ac.price_amount,
       cc.name,
       cc.funding_total,
       ROUND(ac.price_amount/cc.funding_total)
FROM acquisition AS ac
INNER JOIN company AS c ON ac.acquiring_company_id = c.id
INNER JOIN company AS cc ON ac.acquired_company_id = cc.id
WHERE ac.price_amount > 0 AND cc.funding_total > 0
ORDER BY ac.price_amount DESC, cc.name ASC
LIMIT 10

---21---
Выгрузите таблицу, в которую войдут названия компаний из категории social, получившие финансирование с 2010 по 2013 год включительно. Проверьте, что сумма инвестиций не равна нулю. Выведите также номер месяца, в котором проходил раунд финансирования.

SELECT c.name,
       EXTRACT (month FROM funded_at)
FROM company AS c
INNER JOIN funding_round AS f ON c.id = f.company_id
WHERE category_code = 'social'
AND EXTRACT (year FROM funded_at) BETWEEN 2010 AND 2013
AND raised_amount != 0

---22---
Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
номер месяца, в котором проходили раунды;
количество уникальных названий фондов из США, которые инвестировали в этом месяце;
количество компаний, купленных за этот месяц;
общая сумма сделок по покупкам в этом месяце.

WITH
 
a AS (SELECT EXTRACT(MONTH FROM CAST(funding_round.funded_at AS date)) AS month,
     COUNT(DISTINCT fund.name) AS fund_name
     FROM investment 
     JOIN fund ON investment.fund_id = fund.id
     JOIN funding_round ON investment.funding_round_id = funding_round.id
     WHERE (EXTRACT(YEAR FROM CAST(funding_round.funded_at AS date)) BETWEEN 2010 AND 2013)
     AND fund.country_code = 'USA'
     GROUP BY month),
 
b AS (SELECT EXTRACT(MONTH FROM CAST(acquisition.acquired_at AS date)) AS month,
     COUNT(acquisition.acquired_company_id) AS sold_comp,
     SUM(acquisition.price_amount) AS total_sum
     FROM acquisition
     WHERE EXTRACT (year FROM acquired_at) BETWEEN 2010 AND 2013
     GROUP BY month)    
 
SELECT a.month,
       a.fund_name,
       b.sold_comp,
       b.total_sum
FROM a
JOIN b ON a.month = b.month;


---23---
Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. Данные за каждый год должны быть в отдельном поле. Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему.

WITH
     inv_2011 AS (
         SELECT
         country_code,
         AVG(funding_total) AS funding_total
         FROM company
         WHERE EXTRACT(YEAR FROM founded_at) = 2011
         GROUP BY country_code
     ),
     inv_2012 AS (
         SELECT
         country_code,
         AVG(funding_total) AS funding_total
         FROM company
         WHERE EXTRACT(YEAR FROM founded_at) = 2012
         GROUP BY country_code
     ),
     inv_2013 AS (
         SELECT
         country_code,
         AVG(funding_total) AS funding_total
         FROM company
         WHERE EXTRACT(YEAR FROM founded_at) = 2013
         GROUP BY country_code
     )
SELECT inv_2011.country_code,
       inv_2011.funding_total AS ft11,
       inv_2012.funding_total AS ft12,
       inv_2013.funding_total AS ft13
FROM inv_2011
INNER JOIN inv_2012 ON inv_2011.country_code = inv_2012.country_code
INNER JOIN inv_2013 ON inv_2011.country_code = inv_2013.country_code
ORDER BY ft11 DESC
