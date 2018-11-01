﻿USE master
GO
DROP DATABASE LIBRARY
GO 
CREATE DATABASE LIBRARY
GO
USE LIBRARY
GO
CREATE TABLE ACCOUNT(
		USER_NAME VARCHAR(65) PRIMARY KEY, 
		PASSWORD VARCHAR(65),
)
CREATE TABLE STUDENT(
		ID VARCHAR(15) PRIMARY KEY,
		NAME NVARCHAR(50) NOT NULL,
		PHONE VARCHAR(15) NOT NULL,
		EMAIL VARCHAR(50) NOT NULL,
		IMG IMAGE
)
CREATE TABLE  BOOK(
	SERIAL VARCHAR(15) PRIMARY KEY,
	NAME NVARCHAR(50),
	AUTHOR NVARCHAR(50),
	PUBLISH_HOUSE NVARCHAR(50),
	QUANTUM INT,
	IMG IMAGE,
	TAG VARCHAR(300)
)

CREATE TABLE BORROW(
		ID INT IDENTITY(1,1) PRIMARY KEY,
		ID_STUDENT VARCHAR(15),
)

CREATE TABLE BORROW_DETAIL(
		ID  INT NOT NULL,
		SERIAL VARCHAR(15) NOT NULL,
		QUANTUM INT,
		TIME_CREATE DATETIME,
		BORROW_TIME INT,
		COMMENT NVARCHAR(50)
)

CREATE TABLE LOG(
		ACTION NVARCHAR(100),
		TIME_CREATE DATETIME
)

ALTER TABLE BORROW
ADD CONSTRAINT FK_STUDENT_BORROW
FOREIGN KEY (ID_STUDENT) REFERENCES STUDENT(ID) ON UPDATE CASCADE;

ALTER TABLE BORROW_DETAIL
ADD CONSTRAINT FK_BORROW
FOREIGN KEY (ID) REFERENCES BORROW(ID);

ALTER TABLE BORROW_DETAIL
ADD CONSTRAINT FK_BOOKBORROW
FOREIGN KEY (SERIAL) REFERENCES BOOK(SERIAL) ON UPDATE CASCADE;

GO

----------------------------------------------------------------------------------------------------------------------LOG----------------------------------------------------------------------------------------------------------------------------------------------------------------
--Trigger auto update database log
--BOOK
CREATE TRIGGER TRIG_UPDATE_LOG_BOOK ON BOOK
FOR INSERT, DELETE, UPDATE
AS
BEGIN
	DECLARE @EVENT NVARCHAR(100)
	IF UPDATE(NAME) OR UPDATE(AUTHOR) OR UPDATE(PUBLISH_HOUSE) OR UPDATE(QUANTUM) OR UPDATE(IMG) OR UPDATE(TAG)
			BEGIN
				SET @EVENT = CONCAT('UPDATE BOOK HAVE SERIAL ', (SELECT SERIAL FROM INSERTED))
				EXEC PROC_INSERT_LOG_EVENT @EVENT
			END
	ELSE
		IF (SELECT COUNT(*) FROM  INSERTED) > 0
			BEGIN
				SET @EVENT = CONCAT('INSERT BOOK HAVE SERIAL ', (SELECT SERIAL FROM INSERTED))
				EXEC PROC_INSERT_LOG_EVENT @EVENT
			END
		ELSE
			IF (SELECT COUNT(*) FROM  DELETED) > 0
				BEGIN
					SET @EVENT = CONCAT('DELETE BOOK HAVE SERIAL ', (SELECT SERIAL FROM DELETED))
					EXEC PROC_INSERT_LOG_EVENT @EVENT
				END
END
GO
--ACCOUNT
CREATE TRIGGER TRIG_UPDATE_LOG_ACCOUNT ON ACCOUNT
FOR INSERT, DELETE, UPDATE
AS
BEGIN
	DECLARE @EVENT NVARCHAR(100)
	IF UPDATE(PASSWORD)
			BEGIN
				SET @EVENT = CONCAT('UPDATE PASSWORD FOR USER ', (SELECT USER_NAME FROM INSERTED))
				EXEC PROC_INSERT_LOG_EVENT @EVENT
			END
		ELSE
			IF (SELECT COUNT(*) FROM  DELETED) > 0
				BEGIN
					SET @EVENT = CONCAT('DELETE USER ', (SELECT USER_NAME FROM DELETED))
					EXEC PROC_INSERT_LOG_EVENT @EVENT
				END
	ELSE
			IF (SELECT COUNT(*) FROM  INSERTED) > 0
				BEGIN
					SET @EVENT = CONCAT('CREATE USE ', (SELECT USER_NAME FROM INSERTED))
					EXEC PROC_INSERT_LOG_EVENT @EVENT
				END
END
GO
--STUDENT
CREATE TRIGGER TRIG_UPDATE_LOG_STUDENT ON STUDENT
FOR INSERT, DELETE, UPDATE
AS
BEGIN
	DECLARE @EVENT NVARCHAR(100)
	IF UPDATE(NAME) OR UPDATE(PHONE) OR UPDATE(EMAIL) OR UPDATE(IMG)
			BEGIN
				SET @EVENT = CONCAT('UPDATE STUDENT ID ', (SELECT ID FROM INSERTED))
				EXEC PROC_INSERT_LOG_EVENT @EVENT
			END
	
	ELSE
		IF (SELECT COUNT(*) FROM  INSERTED) > 0
			BEGIN
				SET @EVENT = CONCAT('INSERT USER ID ', (SELECT ID FROM INSERTED))
				EXEC PROC_INSERT_LOG_EVENT @EVENT
			END
		ELSE
			IF (SELECT COUNT(*) FROM  DELETED) > 0
				BEGIN
					SET @EVENT = CONCAT('DELETE STUDENT ID ', (SELECT ID FROM DELETED))
					EXEC PROC_INSERT_LOG_EVENT @EVENT
				END
END
GO
--BORROW
CREATE TRIGGER TRIG_UPDATE_LOG_BORROW ON BORROW
FOR INSERT, DELETE, UPDATE
AS
BEGIN
	DECLARE @EVENT NVARCHAR(100)
	DECLARE @SERIAL VARCHAR(15)
	IF (SELECT COUNT(*) FROM  INSERTED) > 0
		BEGIN
			DECLARE CUR_BORROW_BOOK CURSOR
			FOR SELECT SERIAL 
					 FROM INSERTED, BORROW_DETAIL
					 WHERE INSERTED.ID = BORROW_DETAIL.ID
			OPEN CUR_BORROW_BOOK
				FETCH NEXT FROM CUR_BORROW_BOOK INTO @SERIAL
				SET @EVENT = CONCAT('CREATE BORROW_CARD ID : ', (SELECT ID FROM INSERTED ), ' - STUDENT ', (SELECT ID_STUDENT FROM INSERTED), 'BOOK ID ', @SERIAL)
				EXEC PROC_INSERT_LOG_EVENT @EVENT
			CLOSE CUR_BORROW_BOOK
			DEALLOCATE CUR_BORROW_BOOK
		END
	ELSE
		IF (SELECT COUNT(*) FROM  DELETED) > 0
			BEGIN
				DECLARE CUR_BORROW_BOOK CURSOR
				FOR SELECT SERIAL 
						 FROM INSERTED, BORROW_DETAIL
						 WHERE INSERTED.ID = BORROW_DETAIL.ID
				OPEN CUR_BORROW_BOOK
					FETCH NEXT FROM CUR_BORROW_BOOK INTO @SERIAL
					SET @EVENT = CONCAT('DELETE BORROW_CARD ID : ', (SELECT ID FROM DELETED ), ' - STUDENT ', (SELECT ID_STUDENT FROM DELETED), 'BOOK ID ', @SERIAL)
					EXEC PROC_INSERT_LOG_EVENT @EVENT
				CLOSE CUR_BORROW_BOOK
				DEALLOCATE CUR_BORROW_BOOK
			END
END
GO
--DROP PROC PROC_LOGIN_EVENT
CREATE PROC PROC_LOGIN_EVENT @USER_NAME VARCHAR(65)
AS
	BEGIN
		SET @USER_NAME = CONCAT('LOGIN WITH USER NAME ', @USER_NAME)
		EXEC PROC_INSERT_LOG_EVENT @USER_NAME
	END
CREATE PROC PROC_LOGOUT_EVENT @USER_NAME VARCHAR(65)
AS
	BEGIN
		SET @USER_NAME = CONCAT('LOGOUT WITH USER NAME ', @USER_NAME)
		EXEC PROC_INSERT_LOG_EVENT @USER_NAME
	END
GO
--EXEC PROC_LOGIN_EVENT 'ADSDASD'
CREATE PROC PROC_INSERT_LOG_EVENT @ACTION VARCHAR(100)
AS
	INSERT INTO LOG VALUES(@ACTION, SYSDATETIME())
GO
--delete from log where 1=1
--	select *from ACCOUNT
--select * from log
----------------------------------------------------------------------------------------------------------------------LOG----------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------ACCOUNT----------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROC PROC_INSERT_ACCOUNT @USER_NAME VARCHAR(65), @PASSWORD VARCHAR(65), @SUCC INT OUTPUT
AS
	BEGIN TRY
		INSERT INTO ACCOUNT VALUES (@USER_NAME, @PASSWORD)
		SET @SUCC = @@ROWCOUNT
	END TRY
	BEGIN CATCH
		SET @SUCC = @@ROWCOUNT
	RETURN
	END CATCH
GO
--DECLARE @SUCC INT 
--EXEC PROC_INSERT_ACCOUNT 'SSSS','SSSSS',@SUCC OUTPUT
--SELECT STR(@SUCC, 10)

--EXEC PROC_INSERT_ACCOUNT(
--UPDATE ACCOUNT 
--	SET USER_NAME = 'TAMDAULONG207', PASSWORD = '1'
--	WHERE USER_NAME = 'LONG'

--SELECT * FROM ACCOUNT
--DELETE FROM ACCOUNT WHERE USER_NAME = 'LONG'
GO
CREATE FUNCTION DBO.FUNCTION_LOGIN_ACCOUNT(@USER_NAME VARCHAR(65), @PASSWORD VARCHAR(65))
RETURNS TABLE
AS
RETURN
		SELECT USER_NAME FROM ACCOUNT WHERE USER_NAME = @USER_NAME AND PASSWORD = @PASSWORD
GO
--SELECT * FROM FUNCTION_LOGIN_ACCOUNT('TAMDAULONG207','1')
----------------------------------------------------------------------------------------------------------------------ACCOUNT----------------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------BOOK----------------------------------------------------------------------------------------------------------------------------------------------------------------
--SELECT * FROM BOOK

--INSERT INTO BOOK VALUES('FN01', N'Quốc gia khởi nghiệp', 'Daniel *& Saul Singer', 'AlphaBooks ', 1, Null, 'STARTUP, YOUNG,')

--DROP PROC DBO.PROC_INSERT_BOOK
CREATE PROC PROC_INSERT_BOOK 
	@SERIAL VARCHAR(15), 
	@NAME NVARCHAR(50), 
	@AUTHOR NVARCHAR(50), 
	@PUBLISH_HOUSE NVARCHAR(50), 
	@QUANTUM INT, @IMG IMAGE, 
	@TAG VARCHAR(300)
AS
BEGIN
	INSERT INTO BOOK VALUES(@SERIAL, @NAME, @AUTHOR,@PUBLISH_HOUSE, @QUANTUM, @IMG, @TAG)
end
GO
CREATE PROC PROC_UPDATE_BOOK 
	@SERIAL VARCHAR(15), 
	@NAME NVARCHAR(50), 
	@AUTHOR NVARCHAR(50), 
	@PUBLISH_HOUSE NVARCHAR(50), 
	@QUANTUM INT, @IMG IMAGE, 
	@TAG VARCHAR(300)
AS
BEGIN
	UPDATE BOOK 
	SET NAME = @NAME, AUTHOR = @AUTHOR, PUBLISH_HOUSE = @PUBLISH_HOUSE, QUANTUM = @QUANTUM, IMG = @IMG, TAG = @TAG
	WHERE SERIAL = @SERIAL
end
GO
CREATE PROC PROC_DELETE_BOOK 
	@SERIAL VARCHAR(15)
AS
	DELETE BOOK 
	WHERE SERIAL= @SERIAL

GO

--EXEC DBO.PROC_UPDATE_BOOK 'FN03d2', N'ssdadasdasdasdassdass', 'sssger', 'AlssssphaBooks ', 1, Null, 'STARTUP, YOUNG,'--
--select * from log order by TIME_CREATE
--END
--DROP FUNCTION FUNCTION_BOOK_WITH_TAG
CREATE FUNCTION DBO.FUNCTION_FIND_BOOK_WITH_TAG (@TAG VARCHAR(15))
RETURNS TABLE
AS
RETURN 
	SELECT * FROM BOOK WHERE TAG LIKE (CONCAT('%',@TAG,'%'))

GO

CREATE FUNCTION FUNCTION_GET_ALL_BOOK_NAME ()
RETURNS TABLE
AS
RETURN 
	SELECT NAME FROM BOOK

GO

CREATE FUNCTION FUNCTION_GET_ALL_BOOK_SERIAL ()
RETURNS TABLE
AS
RETURN 
	SELECT SERIAL FROM BOOK

GO

--select *from book where SERIAL  = 'FN01' and NAME like '%'

--CREATE FUNCTION FUNCTION_FIND_BOOK(@SERIAL NVARCHAR(15)

--SELECT * FROM FUNCTION_BOOK_WITH_TAG('EEE')
----------------------------------------------------------------------------------------------------------------------BOOK----------------------------------------------------------------------------------------------------------------------------------------------------------------
