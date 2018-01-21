Solutions to workshop questions
===============================

Note that many of the answers below return the full result of the query which may be much more data than you want to transfer into an R dataframe (and the transfer itself might take the bulk of the time used).

The answers are posed in terms of a query from R, but the SQL syntax can used without modification in Python.

# Basic queries

- Find the oldest users in the database

```
dbGetQuery(db, "select * from users order by age desc limit 10")
dbGetQuery(db, "select * from users where age > 70 order by age desc limit 10")
dbGetQuery(db, "select * from users where age > 80")
```

- What are some of the tags that are used?

```
dbGetQuery(db, "select * from questions_tags limit 20")
```

- How many records are in each of the tables in the database?

```
for(tb in dbListTables(db))
   cat(tb, dbGetQuery(db, paste0("select count(*) from ", tb))[[1]], '\n', sep = ' ')
```

# Basic joins

- How many questions have the Python tag.

```
result <- dbGetQuery(db, "select count(*) from questions Q join questions_tags T
               on Q.questionid = T.questionid
               where T.tag = 'python'")
```

- Find the questions with answers that have scores greater than 100.

```
result <- dbGetQuery(db, "select * from questions Q join answers A
               on Q.questionid = A.questionid
               where A.score > 100")
```

- Find the question that has the answer with the maximum score.

```
result <- dbGetQuery(db, "select max(score) from answers")[[1]]
dbGetQuery(db, paste0("select * from questions Q join answers A
               on Q.questionid = A.questionid
               where A.score = ", result))
```

Note: this actually returns nothing, presumably because that question was asked before January 1, 2016.

# Group by

- Who has provided the most answers?

```
result <- dbGetQuery(db, "select userid, age, location, count(*) as n
       from questions join users on ownerid = userid group by userid
       order by n desc limit 1")
```

- Amongst the Berkeley users, who has the most answers?

```
result <- dbGetQuery(db, "select userid, age, location, count(*) as n
       from questions join users on ownerid = userid
       where location like '%berkeley%'  
       group by userid
       order by n desc limit 1")
```

- Find the top few most answered questions.

```
result <- dbGetQuery(db, "select *, count(*) as n
       from questions Q join answers A on Q.questionid = A.questionid
       group by Q.questionid order by n desc limit 5")
```

- What is the average score on questions, grouped by tag?

```
result <- dbGetQuery(db, "select avg(score) as avg, count(*) as n, tag from
       questions Q join questions_tags T on Q.questionid = T.questionid
       group by tag order by avg desc limit 20")
```

# Joins


- Run a query that produces one row for every question-tag pair. Check you get the same result with an explicit inner join and an implicit inner join.

```
dbGetQuery(db, "select count(*) from questions join questions_tags using(questionid)")
dbGetQuery(db, "select count(*) from questions Q, questions_tags T where
        Q.questionid = T.questionid")
```

- Run a query that produces one row for every question-answer pair, including answers without quetions. How many such answers are there?


```
dbGetQuery(db, "select * from answers left outer join
               questions using(questionid) where questions.title is NULL")
```

- How many questions are tagged with both 'R' and 'python'? Be careful - it's easy to overcount here.

```
dbGetQuery(db, "select count(*) from questions_tags T1 join questions_tags T2
               using(questionid) where T1.tag = 'r' and T2.tag = 'python'")

```

# Distinct

- How many users have asked a question with a Python tag. How about an R tag? 

```
dbGetQuery(db, "select count(distinct ownerid) from questions Q join questions_tags
               using(questionid) where tag = 'python'")
dbGetQuery(db, "select count(distinct ownerid) from questions Q join questions_tags
               using(questionid) where tag = 'r'")
```

# Set operations

- How many answers have no questions (again)? Figure out how to do this with a set operation rather than an outer join.


```
result <- dbGetQuery(db, "select questionid from questions except select questionid from answers")
nrow(result)
result <- dbGetQuery(db, "select count(*) from (
       select questionid from questions except select questionid from answers)")
```

- How would you tabulate the combined number of questions and answers for each month of each year? You'd need a string operation not available in SQLite to extract the month-year only from the dates -- for the purpose of the question assume you have a field named 'year-month'.

```
## this introduces a problem - why? Try it!
dbGetQuery(db, "create view qa as select questionid, month-year from questions union
               questionid, month-year from answers")
## instead:
## two-step solution
dbGetQuery(db, "create view qa as select questionid as id, month-year from questions union
               answerid as id, month-year from answers")
dbGetQuery(db, "select count(*) as n from qa group by month-year")
## one-step solution (uses a subquery as discussed in next couple slides)
dbGetQuery(db, "select count(*) as n from (select questionid as id, month-year
               from questions union answerid as id, month-year from answers)
               group by month-year")
```
      

# Subqueries

- What does the query on the previous slide do?

In the subquery, it finds the maximum viewcount for questions by tag. Then it chooses only the questions whose viewcount is at least as big as the maximum viewcount for the tag of the question. So it is finding the most viewed question(s) for each tag (there might be ties). 

- How many answers are there without questions (again - do it with a subquery).

```
dbGetQuery(db, "select count(*) from questions where questionid not in (select distinct questionid from answers)")
```

- Use a subquery to write a query that would return the tags for questions asked by users older than 75.

```
result <- dbGetQuery(db, "select tag from questions_tags join questions using(questionid)
               where ownerid in (select userid from users where age > 75)")
```

- Now extend that to count the number of questions for each tag for the older users. We could see if that were different from the most-used tags seen in an early slide.

```
dbGetQuery(db, "select tag, count(*) as n from questions_tags group by tag
               order by n desc limit 20")
dbGetQuery(db, "select tag, count(tag) as n from questions_tags
               join questions using(questionid)
               where ownerid in (select userid from users where age > 75)
               group by tag order by n desc limit 20")
```

- What's wrong with the following query as an attempt to determine the average upvotes for Python-posting users? Note that the only way to do this is with the subquery we saw recently.

```
dbGetQuery(db, "select avg(upvotes) from questions Q , questions_tags T, users U
               where Q.questionid = T.questionid and
               Q.ownerid = U.userid and
               tag = 'python'")
```

This has as many rows as Python-tagged questions, so it weights each user by the
number of Python questions they've posted, rather than being a simple average
of the upvotes for the Python-posting users.  Alternatively, it averages the upvotes
associated with each Python post. 



# Synthesis breakout questions

- How many questions have 0, 1, 2, 3, etc. answers? How about grouped by tag? 

    - (first question) count A grouped by questionid. Then count the result, grouped by 'n'.
    - (second question) count A grouped by questionid. Join with T and count the res ult grouped by 'n' and tag.

- Suppose you wanted to understand the co-occurrence of tags. Count the number of co-occurrences of all tags.

    - Self join T with T on questionid where T1.tag < T2.tag. Now count, grouping by tag1 and tag2.

- Get the data you would need to do a statistical analysis asking whether users with a higher reputation are more likely to have more or fewer answers to their questions. What about a higher score for their questions?

    - count A grouped by questionid. Join with Q to get question ownerid. Join with users based on question ownerid to get reputation. 
