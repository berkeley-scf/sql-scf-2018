for user in $(cat /tmp/users); do
    echo $user
    psql -c \
    "create user \"${user}\" with password 'test';"
    psql -c \
         "grant all privileges on database wikistats to \"${user}\";"
    psql -d wikistats -c \
         "grant all privileges on table webtraffic to \"${user}\";"   
    psql -c \
         "grant all privileges on database stackoverflow to \"${user}\";"
    psql -d stackoverflow -c \
         "grant all privileges on table questions to \"${user}\";"   
    psql -d stackoverflow -c \
         "grant all privileges on table questions_tags to \"${user}\";"   
    psql -d stackoverflow -c \
         "grant all privileges on table users to \"${user}\";"   
    psql -d stackoverflow -c \
         "grant all privileges on table answers to \"${user}\";"   
done
