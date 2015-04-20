create database ssrs_deploy_example;
go
use ssrs_deploy_example;
go
create table reasonsToDislikeSsrs (id int primary key identity(1,1), reason nvarchar(500));
go

set nocount on;

insert into reasonsToDislikeSsrs (reason) values ('for the sake of your sanity');
go 100 -- repeat the above sql 100 times
