---1---

Найду количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».

SELECT COUNT(parent_id)
FROM stackoverflow.posts
WHERE (score > 300 OR favorites_count >= 100)
AND post_type_id = 1

---2---
Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлю до целого числа.

SELECT ROUND(AVG(count))
FROM (SELECT CAST(DATE_TRUNC('day',creation_date) AS date),
       COUNT(title)
FROM stackoverflow.posts
WHERE creation_date BETWEEN '2008-11-01' AND '2008-11-19'
GROUP BY CAST(DATE_TRUNC('day',creation_date) AS date)
ORDER BY CAST(DATE_TRUNC('day',creation_date) AS date)) AS v

---3---
Сколько пользователей получили значки сразу в день регистрации? Выведу количество уникальных пользователей.

WITH user_dt_badges AS (SELECT u.id,
                            u.creation_date::date - b.creation_date::date AS diff
                   FROM stackoverflow.users AS u
                        JOIN stackoverflow.badges AS b ON u.id = b.user_id
                       WHERE u.creation_date::date - b.creation_date::date = 0)
SELECT COUNT(DISTINCT id)
FROM user_dt_badges

---4---
Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?

SELECT COUNT(DISTINCT(p.id))
FROM stackoverflow.posts AS p
JOIN stackoverflow.votes AS v ON v.post_id = p.id
JOIN stackoverflow.users AS u ON p.user_id = u.id
WHERE u.display_name = 'Joel Coehoorn'
AND v.id >= 1

---5---
Выгружу все поля таблицы vote_types. Добавлю к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.

SELECT *,
      RANK() OVER(ORDER BY id DESC)
FROM stackoverflow.vote_types
ORDER BY id

---6---
Отберу 10 пользователей, которые поставили больше всего голосов типа Close. Отображу таблицу из двух полей: идентификатором пользователя и количеством голосов. Отсортирую данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.

SELECT v.user_id,
       COUNT(*)
FROM stackoverflow.votes AS v
JOIN stackoverflow.vote_types AS vt ON v.vote_type_id = vt.id
WHERE vt.name = 'Close'
GROUP BY v.user_id
ORDER BY count DESC, user_id DESC
LIMIT 10

---7---
Отберу 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отображу несколько полей:
идентификатор пользователя;
число значков;
место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвою одно и то же место в рейтинге.
Отсортирую записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.

SELECT user_id,
       COUNT(id),
       DENSE_RANK() OVER(ORDER BY COUNT(id) DESC)
FROM stackoverflow.badges
WHERE CAST(creation_date AS date) BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY user_id
ORDER BY COUNT(id) DESC, user_id
LIMIT 10

---8---
Сколько в среднем очков получает пост каждого пользователя?
Сформирую таблицу из следующих полей:
заголовок поста;
идентификатор пользователя;
число очков поста;
среднее число очков пользователя за пост, округлённое до целого числа.
Не учитываю посты без заголовка, а также те, что набрали ноль очков.

SELECT
title,
u.id,
score,
round(avg(p.score)over(PARTITION BY u.id))
FROM stackoverflow.posts p
    JOIN stackoverflow.users u ON p.user_id = u.id
 
WHERE p.score != 0 
AND p.title IS NOT null 

---9---
Отображу заголовки постов, которые были написаны пользователями, получившими более 1000 значков. Посты без заголовков не должны попасть в список.

WITH i AS 
(SELECT DISTINCT user_id,
       COUNT(id) OVER(PARTITiON BY user_id) AS b
FROM stackoverflow.badges)

SELECT p.title
FROM i
JOIN stackoverflow.users AS u ON u.id = i.user_id
JOIN stackoverflow.posts AS p ON p.user_id = i.user_id
WHERE p.title != ''
AND b > 1000

---10---
Напишу запрос, который выгрузит данные о пользователях из США (англ. United States). Разделю пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отображу в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу.

SELECT id,
       views,
       CASE
       WHEN views >= 350 THEN 1
       WHEN views < 350 AND views >= 100 THEN 2
       WHEN views < 100 THEN 3
       END
FROM stackoverflow.users
WHERE LOCATION LIKE '%United States%'
AND views != 0

---11---
Дополню предыдущий запрос. Отображу лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. Выведу поля с идентификатором пользователя, группой и количеством просмотров. Отсортирую таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.

WITH tbl AS (SELECT id,
                    views,
                    CASE 
                        WHEN views >= 350 THEN 1
                        WHEN views >= 100 AND views < 350 THEN 2
                        WHEN views < 100  THEN 3
                    END AS rank
             FROM stackoverflow.users
             WHERE views != 0 AND location LIKE '%United States%')
SELECT id,
       rank,
       views 
FROM tbl
WHERE views IN (SELECT  MAX(views) OVER (PARTITION BY rank)
                FROM tbl) 
ORDER BY views DESC, id

---12---
Посчитаю ежедневный прирост новых пользователей в ноябре 2008 года. Сформирую таблицу с полями:
номер дня;
число пользователей, зарегистрированных в этот день;
сумму пользователей с накоплением.

with a as(
 
SELECT DISTINCT EXTRACT(DAY FROM creation_date) AS day_reg,
                        COUNT(id) AS count_id
 
FROM stackoverflow.users u
WHERE creation_date::date BETWEEN '2008-11-01' AND '2008-11-30'
GROUP BY day_reg)
 
SELECT * ,
SUM(count_id) OVER (ORDER BY day_reg)
FROM a

---13---
Для каждого пользователя, который написал хотя бы один пост, найду интервал между регистрацией и временем создания первого поста. Отображу:
идентификатор пользователя;
разницу во времени между регистрацией и первым постом.

WITH a AS
(SELECT u.id AS id,
        u.creation_date AS cd,
        MIN(p.creation_date) AS md
FROM stackoverflow.users AS u
JOIN stackoverflow.posts AS p ON u.id = p.user_id
GROUP BY 1, 2)

SELECT a.id,
       a.md - a.cd
FROM a

---14---
Выведу общую сумму просмотров постов за каждый месяц 2008 года. Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортирую по убыванию общего количества просмотров.

SELECT CAST(DATE_TRUNC('month', creation_date) AS date),
       SUM(views_count)
FROM stackoverflow.posts
WHERE CAST(DATE_TRUNC('month', creation_date) AS date) BETWEEN '2008-01-01' AND '2008-12-31' 
GROUP BY CAST(DATE_TRUNC('month', creation_date) AS date)
ORDER BY sum DESC

---15---
Выведу имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитываю. Для каждого имени пользователя выведу количество уникальных значений user_id. Отсортирую результат по полю с именами в лексикографическом порядке.

SELECT display_name,
       COUNT(DISTINCT p.user_id) AS total_answers
FROM stackoverflow.users AS u
JOIN stackoverflow.posts AS p ON u.id=p.user_id
WHERE post_type_id=2
AND p.creation_date::date <= u.creation_date::date + INTERVAL '1 month'
GROUP BY display_name
HAVING COUNT(DISTINCT p.id) > 100

---16---
Выведу количество постов за 2008 год по месяцам. Отберу посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. Отсортирую таблицу по значению месяца по убыванию.

SELECT DATE_TRUNC('month',creation_date)::date AS month,
        COUNT (id) AS num_of_posts
FROM stackoverflow.posts
WHERE user_id IN 
        (SELECT DISTINCT u.id
         FROM stackoverflow.users AS u
         JOIN stackoverflow.posts AS p ON u.id = p.user_id
         WHERE CAST(u.creation_date AS date) BETWEEN '2008-09-01' AND '2008-09-30'
         AND CAST(p.creation_date AS date) BETWEEN '2008-12-01' AND '2008-12-31')
GROUP BY month
ORDER BY month DESC

---17---
Используя данные о постах, выведу несколько полей:
идентификатор пользователя, который написал пост;
дата создания поста;
количество просмотров у текущего поста;
сумму просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.

SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER(PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts

---18---
Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? Для каждого пользователя отберу дни, в которые он или она опубликовали хотя бы один пост. Нужно получить одно целое число.

WITH dis AS
(SELECT DISTINCT user_id,
       CAST(DATE_TRUNC('day', creation_date) AS date)
FROM stackoverflow.posts
WHERE CAST(creation_date AS date) BETWEEN '2008-12-01' AND '2008-12-07'),

sec AS
(SELECT user_id,
       COUNT(date_trunc)
FROM dis
GROUP BY user_id)

SELECT ROUND(AVG(count))
FROM sec

---19---
На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отображу таблицу со следующими полями:
номер месяца;
количество постов за месяц;
процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлю значение процента до двух знаков после запятой.

WITH a1 AS 
(SELECT EXTRACT(MONTH FROM creation_date) AS month, 
        COUNT(id) AS cnt_id 
 FROM stackoverflow.posts 
 WHERE DATE_TRUNC('month', creation_date)::date BETWEEN '2008-09-01' AND '2008-12-31' 
 GROUP BY 1) 
 
 SELECT *, 
        ROUND((cnt_id - LAG(cnt_id, 1) OVER(ORDER BY month)) * 100.0 / LAG(cnt_id) OVER(ORDER BY month), 2) 
 FROM a1

---20---
Выгружу данные активности пользователя, который опубликовал больше всего постов за всё время. Выведу данные за октябрь 2008 года в таком виде:
номер недели;
дата и время последнего поста, опубликованного на этой неделе.

WITH posting_user AS (
	SELECT
        		user_id,
                COUNT(DISTINCT id)
        		FROM stackoverflow.posts
        		GROUP BY posts.user_id
        		ORDER BY 2 DESC
        		LIMIT 1)

SELECT EXTRACT(WEEK FROM creation_date) AS week_number
      ,MAX(creation_date)
FROM stackoverflow.posts
WHERE CAST(DATE_TRUNC('month', creation_date) AS date) = '2008-10-01'
  AND user_id IN (SELECT user_id
                  FROM posting_user
                  )
GROUP BY week_number;
