create table comments (
    id integer primary key,
    body text,
    username text,
    chat text,
    partner text
);

create table followers (
    id integer primary key,
    username text,
    follower text
);
