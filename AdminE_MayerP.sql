/* 1. Create databse */
/*MS DOCS https://docs.microsoft.com/en-us/sql/relational-databases/databases/create-a-database?view=sql-server-ver15*/
CREATE DATABASE [Employee]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Employee', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Employee.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Employee_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Employee_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
/*1.c Collation*/
 COLLATE Hungarian_CI_AS
GO
/*1.a Add second filegroup [SalesData]*/
/*MS DOCS https://docs.microsoft.com/en-us/sql/relational-databases/databases/database-files-and-filegroups?view=sql-server-ver15*/

ALTER DATABASE [Employee] ADD FILEGROUP [SalesData]
GO
ALTER DATABASE [Employee] SET COMPATIBILITY_LEVEL = 150
GO
ALTER DATABASE [Employee] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Employee] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Employee] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Employee] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Employee] SET ARITHABORT OFF 
GO
ALTER DATABASE [Employee] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Employee] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Employee] SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF)
GO
ALTER DATABASE [Employee] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Employee] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Employee] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Employee] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Employee] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Employee] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Employee] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Employee] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Employee] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Employee] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Employee] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Employee] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Employee] SET  READ_WRITE 
GO
/*1.d Revovery model full*/
ALTER DATABASE [Employee] SET RECOVERY FULL
GO
ALTER DATABASE [Employee] SET  MULTI_USER 
GO
ALTER DATABASE [Employee] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Employee] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [Employee] SET DELAYED_DURABILITY = DISABLED 
GO
USE [Employee]
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = Off;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = Primary;
GO
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = On;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = Primary;
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = Off;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = Primary;
GO
USE [Employee]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [Employee] MODIFY FILEGROUP [PRIMARY] DEFAULT

/* 1.b 
Modify primary file size to 200MB, 10% increase
Create secondary file with Employee_data logical and Employees.ndf physical name, 
file size 200MB , increase 10% */
/*MS DOCS https://docs.microsoft.com/en-us/sql/relational-databases/databases/add-data-or-log-files-to-a-database?view=sql-server-ver15*/

ALTER DATABASE [Employees] MODIFY FILE ( NAME = N'Employees', SIZE = 204800KB , FILEGROWTH = 10%)
GO
ALTER DATABASE [Employees] ADD FILE ( NAME = N'Employee_data', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Employees.ndf' , SIZE = 204800KB , FILEGROWTH = 10%) TO FILEGROUP [SalesData]
GO
GO

USE [master]
GO
--2. Create EmployeeAdmin login w/ user mapping into Employee
--MS DOCS https://docs.microsoft.com/en-us/sql/relational-databases/security/authentication-access/create-a-login?view=sql-server-ver15
--MS DOCS https://docs.microsoft.com/en-us/sql/relational-databases/security/authentication-access/create-a-database-user?view=sql-server-ver15*/

CREATE LOGIN [EmployeeAdmin] WITH PASSWORD=N'Pa55w.rd', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
USE [Employees]
GO
CREATE USER [EmployeeAdmin] FOR LOGIN [EmployeeAdmin]
GO

USE [master]
GO
/*2 Create EmployeeRO login w/ user mapping into Employee */
CREATE LOGIN [EmployeeRO] WITH PASSWORD=N'Pa55w.rd', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
USE [Employees]
GO
CREATE USER [EmployeeRO] FOR LOGIN [EmployeeRO]
GO


--3. Add bulkadmin server role to EmployeeAdmin
--MS DOCS https://docs.microsoft.com/en-us/sql/relational-databases/security/authentication-access/server-level-roles?view=sql-server-ver15

ALTER SERVER ROLE [bulkadmin] ADD MEMBER [EmployeeAdmin]
GO


--4. Add user roles 
--MS DOCS https://docs.microsoft.com/en-us/sql/relational-databases/security/authentication-access/database-level-roles?view=sql-server-ver15

--Add db_owner role to EmployeeAdmin in Employee

USE [Employees]
GO
ALTER ROLE [db_owner] ADD MEMBER [EmployeeAdmin]
GO

--Add db_datareader role to EmployeeRO in Employee

USE [Employees]
GO
ALTER ROLE [db_datareader] ADD MEMBER [EmployeeRO]
GO


--6. Create Application Role HRApp 

USE [Employees]
GO
CREATE APPLICATION ROLE [HRApp] WITH PASSWORD = N'Pa55w.rd'
GO
USE [Employees]
GO
--Add db_datareader permission to HRApp-nak
ALTER AUTHORIZATION ON SCHEMA::[db_datareader] TO [HRApp]
GO


-- 7. Apply masking

--MS DOCS https://docs.microsoft.com/en-us/sql/relational-databases/security/dynamic-data-masking?view=sql-server-ver15

USE [Employees]
GO
--Mask phone using 'default' 
ALTER TABLE dbo.PersonPhone  
ALTER COLUMN PhoneNumber nvarchar(25) MASKED WITH (FUNCTION = 'default()'); 
GO
--Mask email using 'default' 
ALTER TABLE dbo.EmailAddress  
ALTER COLUMN EmailAddress nvarchar(50) MASKED WITH (FUNCTION = 'default()'); 
GO
--Umask EmployeeRO user 
GRANT UNMASK to EmployeeRO 
GO

--8. Full backup
BACKUP DATABASE [Employees] TO  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Employees.bak' 
WITH NOFORMAT, NOINIT,  NAME = N'EmployeesFullBackup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- Diff backup
BACKUP DATABASE [Employees] TO  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Employees.bak' 
WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'EmployeeDiffBackup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

--Log backup 
BACKUP LOG [Employees] TO  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Employees.bak' 
WITH NOFORMAT, NOINIT,  NAME = N'EmployeeLogBackup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

--9. Create three jobs calling defined backup scripts 

--Create job running EmployeeFullBackup

USE [msdb]
GO
 
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'EmployeeFullBackup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DESKTOP-572KTJQ\Peter', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'EmployeeFullBackup', @server_name = N'DESKTOP-572KTJQ'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'EmployeeFullBackup', @step_name=N'EmployeeFullBackup', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'BACKUP DATABASE [Employees] TO  DISK = N''C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Employees.bak'' 
WITH NOFORMAT, NOINIT,  NAME = N''EmployeesFullBackup'', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'EmployeeFullBackup', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DESKTOP-572KTJQ\Peter', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO

USE [msdb]
GO

DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'EmployeeDiffBackup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DESKTOP-572KTJQ\Peter', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'EmployeeDiffBackup', @server_name = N'DESKTOP-572KTJQ'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'EmployeeDiffBackup', @step_name=N'EmployeeDiffBackup', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'BACKUP DATABASE [Employees] TO  DISK = N''C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Employees.bak'' 
WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N''EmployeeDiffBackup'', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'EmployeeDiffBackup', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DESKTOP-572KTJQ\Peter', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO

--Create job running EmployeeLogBackup

USE [msdb]
GO

DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'EmployeeLogBackup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DESKTOP-572KTJQ\Peter', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'EmployeeLogBackup', @server_name = N'DESKTOP-572KTJQ'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'EmployeeLogBackup', @step_name=N'1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'BACKUP LOG [Employees] TO  DISK = N''C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Employees.bak'' WITH NOFORMAT, NOINIT,  NAME = N''EmployeeLogBackup'', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'EmployeeLogBackup', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DESKTOP-572KTJQ\Peter', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO

--Schedule backup 
USE [msdb]
GO
--EmployeeFullBackup schedule: daily, at 3:00:00
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_id=N'9d9a9036-8b81-4c80-b541-b8728a7475d9', @name=N'EmployeeFullbackup', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210217, 
		@active_end_date=99991231, 
		@active_start_time=30000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO

--EmployeeDiffBackup schedule: daily, at 10:00:00, 14:00:00, 18:00:00
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_id=N'd51ac4fd-68ac-4e23-978f-753bda74e044', @name=N'EmployeeDiffBackup', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=4, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210217, 
		@active_end_date=99991231, 
		@active_start_time=100000, 
		@active_end_time=190000, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO

--EmployeeLogBackup schedule: daily 8:00:00 to 19:00:00 , except schedule diff backup times 
USE [msdb]
GO
--EmployeeLogBackup schedule: daily at 8:00:00, 9:00:00

DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_id=N'b2c377f3-3ede-4a02-8f52-5b09f9469836', @name=N'EmployeeLogBackup', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210217, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=90100, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO

USE [msdb]
GO
--EmployeeLogBackup schedule: daily at 11:00:00, 12:00:00, 13:00:00

DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_id=N'b2c377f3-3ede-4a02-8f52-5b09f9469836', @name=N'EmployeeLogBackup_2', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210217, 
		@active_end_date=99991231, 
		@active_start_time=110000, 
		@active_end_time=130100, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
USE [msdb]
GO
--EmployeeLogBackup schedule: daily at 15:00:00, 16:00:00, 17:00:00

DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_id=N'b2c377f3-3ede-4a02-8f52-5b09f9469836', @name=N'EmployeeLogBackup_3', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210217, 
		@active_end_date=99991231, 
		@active_start_time=150000, 
		@active_end_time=170100, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO

USE [msdb]
GO
--EmployeeLogBackup schedule: daily at 19:00:00

DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_id=N'b2c377f3-3ede-4a02-8f52-5b09f9469836', @name=N'EmployeeLogBackup_4', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210217, 
		@active_end_date=99991231, 
		@active_start_time=190000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
--Simulated job run

--3:00:00 Full backup run 
--8:00:00 Log backup run
--9:00:00 Log backup run
--10:00:00 Diff backup run
--11:00:00 Log backup run


--11. Point-in-time recovery at 11:13 

USE [master]
BACKUP LOG [Employees] TO  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Employees_LogBackup_2021-02-18_06-39-34.bak' WITH NOFORMAT, NOINIT,  NAME = N'Employees_LogBackup_2021-02-18_06-39-34', NOSKIP, NOREWIND, NOUNLOAD,  NORECOVERY ,  STATS = 5
RESTORE DATABASE [Employees] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Employees.bak' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 5
RESTORE DATABASE [Employees] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Employees.bak' WITH  FILE = 4,  NORECOVERY,  NOUNLOAD,  STATS = 5
RESTORE LOG [Employees] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Employees.bak' WITH  FILE = 5,  NORECOVERY,  NOUNLOAD,  STATS = 5
RESTORE LOG [Employees] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\Employees_LogBackup_2021-02-18_06-39-34.bak' WITH  NOUNLOAD,  STATS = 5,  STOPAT = N'2021-02-18T11:13:00'

GO

--12. Full perimission for EmployeeAdmin to run jobs 
-- Operator level role was chosen to allow running all jobs, not only own jobs

--MS DOCS Add server agent role https://docs.microsoft.com/en-us/sql/ssms/agent/configure-a-user-to-create-and-manage-sql-server-agent-jobs?view=sql-server-ver15
--MS DOCS Server agent role descriptions https://docs.microsoft.com/en-us/sql/ssms/agent/sql-server-agent-fixed-database-roles?view=sql-server-ver15


USE [msdb]
GO
CREATE USER [EmployeeAdmin] FOR LOGIN [EmployeeAdmin]
GO
USE [msdb]
GO
ALTER ROLE [SQLAgentOperatorRole] ADD MEMBER [EmployeeAdmin]
GO

--13. Create LongSQLRun Extended Event to record transactions exceeding one minute

--MS DOCS https://docs.microsoft.com/en-us/sql/relational-databases/extended-events/quick-start-extended-events-in-sql-server?view=sql-server-ver15
--MS DOCS https://docs.microsoft.com/en-us/sql/relational-databases/extended-events/extended-events?view=sql-server-ver15


CREATE EVENT SESSION [LongSQLRun] ON SERVER 
ADD EVENT sqlserver.rpc_completed(SET collect_statement=(1)
    WHERE ([duration]>(60000000)))
ADD TARGET package0.ring_buffer
WITH (MAX_DISPATCH_LATENCY=100 SECONDS)
GO

--Activate LongSQLRun 

ALTER EVENT SESSION [LongSQLRun]
ON SERVER  
STATE = START;
GO  






