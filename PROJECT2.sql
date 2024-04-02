/* 1.How many times does the average user post? */

SELECT AVG(posts_per_user) AS average_posts_per_user
FROM (
    SELECT u.id AS user_id, COUNT(p.id) AS posts_per_user
    FROM users u 
    LEFT JOIN photos p ON p.user_id = u.id
    GROUP BY u.id
    ORDER BY user_id
	) AS post_counts;
    
    -- subquery
    SELECT u.id AS user_id, COUNT(p.id) AS posts_per_user
    FROM users u 
    LEFT JOIN photos p ON p.user_id = u.id
    GROUP BY u.id
    ORDER BY user_id  ;
                    


/* 2.Find the top 5 most used hashtags.*/

SELECT tag_name, 
	   RANK() OVER (order by tag_count DESC) as tag_rank
FROM
      (SELECT t.tag_name, count(pt.tag_id) AS tag_count
       FROM photo_tags pt
       INNER JOIN tags t ON t.id = pt.tag_id  
	   GROUP BY tag_id
       ORDER BY tag_count DESC
       LIMIT  5 ) as photo_tag_count ;


/* 3.Find users who have liked every single photo on the site.*/


SELECT u.id as user_id,
       u.username,
       count(DISTINCT lk.photo_id) AS photo_liked,
	   CASE WHEN count(DISTINCT lk.photo_id)  =  (SELECT count(*) FROM photos)
       THEN "ALL" 
       ELSE "NOT_ALL" 
       END AS LIKED
FROM likes lk
INNER JOIN users u ON u.id = lk.user_id
GROUP BY u.id 
HAVING LIKED = 'ALL'
ORDER BY user_id  ;

/* 4.Retrieve a list of users along with their usernames and the rank of their 
     account creation, ordered by the creation date in ascending order.*/

SELECT username,
       DENSE_RANK() OVER (ORDER BY created_at ) AS creation_RANK
FROM users  ;

/* 5.List the comments made on photos with their comment texts, photo URLs, 
     and usernames of users who posted the comments. Include the comment count
     for each photo*/
     
CREATE Temporary Table comment_count
        (SELECT c.photo_id ,
        count(DISTINCT c.id) as total_comment
         FROM comments c
         Left JOIN photos p on p.id = c.photo_id
         GROUP BY c.photo_id ) ;

SELECT
	  c.comment_text,
      p.image_url,
      u.username,
      p.id as photo_id,
      cc.total_comment
FROM photos p
JOIN comments c ON p.id = c.photo_id
JOIN users u ON c.user_id = u.id
JOIN comment_count cc ON cc.photo_id = c.photo_id
GROUP BY p.id, c.id , cc.total_comment
ORDER BY p.id   ;



/* 6.For each tag, show the tag name and the number of photos associated with that tag.
     Rank the tags by the number of photos in descending order.*/

WITH tag_rank AS
(SELECT pt.tag_id, t.tag_name,
        count(photo_id) AS total_tag_photos
FROM photo_tags pt
INNER JOIN tags t ON t.id = pt.tag_id
GROUP BY tag_id
ORDER BY total_tag_photos DESC  )  

SELECT tag_id, tag_name, total_tag_photos,
       RANK() OVER (ORDER BY total_tag_photos DESC) AS tag_rank
FROM tag_rank  ; 
       
	
       

/* 7.List the usernames of users who have posted photos along with the count of photos 
     they have posted. Rank them by the number of photos in descending order.*/

WITH user_photos AS
(SELECT u.id AS user_id, u.username, count(p.id) AS total_post
FROM users u
INNER JOIN photos p ON p.user_id = u.id
GROUP BY user_id )

SELECT user_id, username, total_post, 
	   DENSE_RANK() OVER (ORDER BY total_post DESC) AS totalpost_Rank
FROM user_photos ;
       

/* 8.Display the username of each user along with the creation date of their first posted
	 photo and the creation date of their next posted photo.*/
     
WITH CTE AS

(SELECT p.user_id,
       u.username,
       FIRST_VALUE(p.created_at) OVER (PARTITION BY p.user_id ORDER BY p.created_at) AS first_post_date ,     
       LEAD(p.created_at) OVER (PARTITION BY p.user_id ORDER BY p.created_at) AS next_post_date,
       ROW_NUMBER() OVER (PARTITION BY p.user_id ORDER BY p.created_at ) AS Row_num
FROM photos p
INNER JOIN users u ON u.id = p.user_id
ORDER BY p.user_id )

SELECT *
FROM CTE 
HAVING Row_num IN (1) ;



/* 9.For each comment, show the comment text, the username of the commenter, and the comment
     text of the previous comment made on the same photo.*/

SELECT  c.comment_text AS current_comment,
        u.username,
        LAG(c.comment_text) OVER (PARTITION BY c.photo_id ORDER BY c.user_id ) AS previous_comment,
        c.photo_id
        
FROM comments c
INNER JOIN users u ON u.id = c.user_id
GROUP BY c.user_id, c.id ;
     
/*10.Show the username of each user along with the number of photos they have posted and 
	 the number of photos posted by the user before them and after them, based on the
	 creation date.*/
     
 SELECT
       u.id as user_id,
       u.username,
       COUNT(p.id) AS photos_posted,
       LAG(COUNT(p.id)) OVER (ORDER BY u.created_at) AS prev_user_photos,
       LEAD(COUNT(p.id)) OVER (ORDER BY u.created_at) AS next_user_photos
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
GROUP BY u.id, u.created_at
ORDER BY u.created_at ;









