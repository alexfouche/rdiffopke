
echo 'create table revisions (rev integer primary key not null, date datetime not null, enc_sym_key text not null);' |sqlite3 metadata.sqlite3

echo 'create table files (file_id integer primary key not null, enc_path text not null, localpath text not null);' |sqlite3 metadata.sqlite3

echo 'create table file_rev (rev integer not null, file_id integer not null, primary key(rev, file_id));' |sqlite3 metadata.sqlite3

echo 'create table options (name text primary key not null, value text not null);' |sqlite3 metadata.sqlite3


echo 'insert into options (name,value) values('version', '0'); ' |sqlite3 metadata.sqlite3
echo 'insert into options values('dbversion', '1'); ' |sqlite3 metadata.sqlite3

#echo 'create index if not exists ip_idx on squid_hits (ip);' |sqlite3 squid_hits.sqlite3


