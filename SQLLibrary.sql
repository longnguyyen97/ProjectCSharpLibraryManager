﻿USE master
GO
--DROP DATABASE LIBRARY
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
go
ALTER TABLE BORROW
ADD CONSTRAINT FK_STUDENT_BORROW
FOREIGN KEY (ID_STUDENT) REFERENCES STUDENT(ID) ON UPDATE CASCADE;
go
ALTER TABLE BORROW_DETAIL
ADD CONSTRAINT FK_BORROW
FOREIGN KEY (ID) REFERENCES BORROW(ID);
go
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
	IF EXISTS(SELECT * FROM inserted)
			BEGIN
				IF EXISTS(SELECT * FROM deleted)
					BEGIN
						SET @EVENT = CONCAT('UPDATE BOOK HAVE SERIAL ', (SELECT SERIAL FROM INSERTED))
						EXEC PROC_INSERT_LOG_EVENT @EVENT
					END
				ELSE 
						BEGIN
							SET @EVENT = CONCAT('INSERT BOOK HAVE SERIAL ', (SELECT SERIAL FROM INSERTED))
							EXEC PROC_INSERT_LOG_EVENT @EVENT
						END
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
	IF EXISTS(SELECT * FROM inserted)
			BEGIN
				IF EXISTS(SELECT * FROM deleted)
					BEGIN
						SET @EVENT = CONCAT('UPDATE PASSWORD FOR USER ', (SELECT USER_NAME FROM INSERTED))
						EXEC PROC_INSERT_LOG_EVENT @EVENT
					END
				ELSE
					BEGIN
						SET @EVENT = CONCAT('CREATE USE ', (SELECT USER_NAME FROM INSERTED))
						EXEC PROC_INSERT_LOG_EVENT @EVENT
					END
			END
		ELSE
			IF (SELECT COUNT(*) FROM  DELETED) > 0
				BEGIN
					SET @EVENT = CONCAT('DELETE USER ', (SELECT USER_NAME FROM DELETED))
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
	IF EXISTS(SELECT * FROM inserted)
			BEGIN
				IF EXISTS(SELECT * FROM deleted)
					BEGIN
						SET @EVENT = CONCAT('UPDATE STUDENT ID ', (SELECT ID FROM INSERTED))
						EXEC PROC_INSERT_LOG_EVENT @EVENT
					END
				ELSE
					BEGIN
							SET @EVENT = CONCAT('INSERT USER ID ', (SELECT ID FROM INSERTED))
							EXEC PROC_INSERT_LOG_EVENT @EVENT
					END
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
CREATE  TRIGGER TRIG_UPDATE_LOG_BORROW_DETAIL ON BORROW_DETAIL
FOR INSERT, DELETE, UPDATE
AS
BEGIN
	DECLARE @EVENT NVARCHAR(100)
	DECLARE @SERIAL VARCHAR(15)
	DECLARE @ID VARCHAR(15)
	IF (SELECT COUNT(*) FROM  INSERTED) > 0
		BEGIN
			DECLARE CUR_BORROW_BOOK CURSOR
			FOR SELECT SERIAL, BORROW.ID_STUDENT
					 FROM INSERTED, BORROW
					 WHERE INSERTED.ID = BORROW.ID
			OPEN CUR_BORROW_BOOK
			FETCH NEXT FROM CUR_BORROW_BOOK INTO @SERIAL, @ID
				WHILE (@@FETCH_STATUS = 0)
				BEGIN
					SET @EVENT = CONCAT('CREATE BORROW_CARD ID : ', (SELECT TOP 1 ID FROM INSERTED ), ' - STUDENT :  ', @ID , ' - BOOK ID :  ', @SERIAL)
					EXEC PROC_INSERT_LOG_EVENT @EVENT
					FETCH NEXT FROM CUR_BORROW_BOOK INTO @SERIAL, @ID
				END
			CLOSE CUR_BORROW_BOOK
			DEALLOCATE CUR_BORROW_BOOK
		END
END
go
CREATE  TRIGGER TRIG_UPDATE_LOG_BORROW ON BORROW
FOR DELETE
AS
BEGIN
	DECLARE @EVENT NVARCHAR(100)
	IF EXISTS (SELECT *FROM  DELETED)
		BEGIN
					SET @EVENT = CONCAT('DELETE BORROW_CARD ID : ', (SELECT TOP 1 ID FROM DELETED), ' - STUDENT :  ', (SELECT TOP 1 ID_STUDENT FROM DELETED))
					EXEC PROC_INSERT_LOG_EVENT @EVENT
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

go
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
--select * from log order by TIME_CREATE
--END
----------------------------------------------------------------------------------------------------------------------LOG----------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------ACCOUNT----------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROC PROC_INSERT_ACCOUNT 
	@USER_NAME VARCHAR(65), 
	@PASSWORD VARCHAR(65), 
	@SUCC INT OUTPUT
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

CREATE PROC PROC_UPDATE_ACCOUNT 
	@USER_NAME VARCHAR(65), 
	@PASSWORD VARCHAR(65),
	@SUCC INT OUTPUT
AS
	BEGIN TRY
		UPDATE ACCOUNT 
		SET PASSWORD = @PASSWORD
		WHERE USER_NAME = @USER_NAME
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
	@QUANTUM INT, 
	@IMG IMAGE, 
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
	@QUANTUM INT, 
	@IMG IMAGE, 
	@TAG VARCHAR(300)
AS
BEGIN
	UPDATE BOOK 
	SET NAME = @NAME, 
		AUTHOR = @AUTHOR, 
		PUBLISH_HOUSE = @PUBLISH_HOUSE, 
		QUANTUM = @QUANTUM, 
		IMG = @IMG, TAG = @TAG
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
----------------------------------------------------------------------------------------------------------------------STUDENT----------------------------------------------------------------------------------------------------------------------------------------------------------------
--DROP PROC PROC_INSERT_STUDENT
CREATE PROC PROC_INSERT_STUDENT 
	@ID VARCHAR(15), 
	@NAME NVARCHAR(50), 
	@PHONE NVARCHAR(15), 
	@EMAIL VARCHAR(50),
	@IMG IMAGE
AS
BEGIN
	INSERT INTO STUDENT VALUES(@ID, @NAME, @PHONE,@EMAIL, @IMG)
end


GO

CREATE PROC PROC_UPDATE_STUDENT 
	@ID VARCHAR(15), 
	@NAME NVARCHAR(50), 
	@PHONE VARCHAR(15), 
	@EMAIL VARCHAR(50),
	@IMG IMAGE

AS

BEGIN
	UPDATE STUDENT 
	SET NAME = @NAME, 
			EMAIL = @EMAIL,
			PHONE = @PHONE, 
			IMG = @IMG
	WHERE ID = @ID
end

GO
CREATE PROC PROC_DELETE_STUDENT 
	@ID VARCHAR(15)
AS
	DELETE STUDENT 
	WHERE ID= @ID

GO

--EXEC DBO.PROC_UPDATE_STUDENT 'FN03d2', N'ssdadasdasdasdassdass', 'sssger', 'AlssssphaSTUDENTs ', 1, Null, 'STARTUP, YOUNG,'--


CREATE FUNCTION FUNCTION_GET_ALL_STUDENT_NAME ()
RETURNS TABLE
AS
RETURN 
	SELECT NAME FROM STUDENT

GO

CREATE FUNCTION FUNCTION_GET_ALL_STUDENT_ID ()
RETURNS TABLE
AS
RETURN 
	SELECT ID FROM STUDENT

GO


----------------------------------------------------------------------------------------------------------------------STUDENT----------------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------BORROW----------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE FUNCTION FUNCTION_GET_ALL_BORROW_ID ()
RETURNS TABLE
AS
RETURN 
	SELECT ID FROM BORROW
GO



CREATE FUNCTION FUNCTION_GET_STUDENT_BORROW (@ID VARCHAR(15))
RETURNS TABLE
AS
RETURN 
	SELECT  BORROW.ID, SERIAL, QUANTUM
	FROM BORROW, BORROW_DETAIL
	WHERE BORROW_DETAIL.ID = BORROW.ID AND ID_STUDENT = @ID
GO


CREATE FUNCTION FUNCTION_GET_BORROW (@ID VARCHAR(15))
RETURNS TABLE
AS
RETURN 
	SELECT ID_STUDENT,  SERIAL, QUANTUM,TIME_CREATE, BORROW_TIME, COMMENT
	FROM BORROW A, BORROW_DETAIL B
	WHERE A.ID = @ID AND A.ID = B.ID
GO

CREATE PROC PROC_INSERT_BORROW
	@ID_STUDENT VARCHAR(15)
	AS
	INSERT INTO BORROW VALUES (@ID_STUDENT)  
GO
GO
--SHIRONEKO--
CREATE  PROC PROC_DELETE_BORROW
	@ID INT
	AS
	BEGIN
		DELETE BORROW_DETAIL 
			WHERE @ID  = ID
		DELETE BORROW 
			WHERE @ID  = ID
	END 
GO
--SHIRONEKO--
CREATE PROC PROC_INSERT_BORROW_DETAIL
	@ID INT,
	@SERIAL VARCHAR(15),
	@QUANTUM INT,
	@TIME_CREATE DATETIME,
	@BORROW_TIME INT,
	@COMMENT NVARCHAR(50)
	AS
	INSERT INTO BORROW_DETAIL 
		VALUES (@ID, @SERIAL, @QUANTUM, @TIME_CREATE, @BORROW_TIME, @COMMENT)
GO
--exec PROC_INSERT_BORROW_DETAIL 57, 'FN03', 2, '1/8/2017', 1, 'edasdas'
go
CREATE TRIGGER TRIG_UPDATE_QUANTUM ON BORROW_DETAIL
FOR INSERT, DELETE, UPDATE
AS
BEGIN
	DECLARE @SERIAL VARCHAR(15)
	DECLARE @QUANTUM INT
	IF EXISTS(SELECT COUNT(*) FROM  INSERTED)
		BEGIN
			DECLARE CUR_BORROW_BOOK CURSOR
			FOR SELECT INSERTED.SERIAL, INSERTED.QUANTUM
					 FROM INSERTED
			OPEN CUR_BORROW_BOOK
			FETCH NEXT FROM CUR_BORROW_BOOK INTO @SERIAL, @QUANTUM
			WHILE (@@FETCH_STATUS = 0)
				BEGIN
						UPDATE BOOK SET QUANTUM = QUANTUM - @QUANTUM WHERE SERIAL = @SERIAL
						FETCH NEXT FROM CUR_BORROW_BOOK INTO @SERIAL, @QUANTUM
				END
			CLOSE CUR_BORROW_BOOK
			DEALLOCATE CUR_BORROW_BOOK
		END
	IF EXISTS (SELECT * FROM  DELETED)
		BEGIN
			DECLARE CUR_BORROW_BOOK CURSOR
			FOR SELECT SERIAL, QUANTUM 
					 FROM deleted			
			OPEN CUR_BORROW_BOOK
			FETCH NEXT FROM CUR_BORROW_BOOK INTO @SERIAL, @QUANTUM
			WHILE (@@FETCH_STATUS = 0)
				BEGIN
						UPDATE BOOK SET QUANTUM = QUANTUM + @QUANTUM WHERE SERIAL = @SERIAL
						FETCH NEXT FROM CUR_BORROW_BOOK INTO @SERIAL, @QUANTUM
				END
			CLOSE CUR_BORROW_BOOK
			DEALLOCATE CUR_BORROW_BOOK
		END
END
GO
----------------------------------------------------------------------------------------------------------------------BORROW----------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------DATA----------------------------------------------------------------------------------------------------------------------------------------------------------------
GO
--SHIRONEKO--
CREATE VIEW VIEW_BORROW_OVER_TIME
AS
	SELECT A.ID [Mã phiếu], ID_STUDENT [Mã sinh viên], TIME_CREATE [Ngày tạo], BORROW_TIME [Thời gian mượn]
	FROM BORROW A, BORROW_DETAIL B
	WHERE A.ID = B.ID AND ((GETDATE()) - (7*BORROW_TIME)) >  (DAY(TIME_CREATE))
GO
CREATE VIEW VIEW_ALL_BOOK
AS
	SELECT SERIAL [Mã sách], NAME [Tên sách], AUTHOR [Tác giả], PUBLISH_HOUSE [Nhà xuất bản], QUANTUM [Số lượng], IMG [Hình ảnh], TAG [Thể loại]	
	FROM BOOK
GO
CREATE  VIEW VIEW_ALL_STUDENT
AS
	SELECT ID [Mã sinh viên], NAME [Họ và Tên], PHONE [Số điện thoại], EMAIL [Địa chỉ email], IMG [Hình ảnh]	
	FROM STUDENT
GO
CREATE VIEW VIEW_ALL_BORROW_CARD
AS
	SELECT A.ID [Mã phiếu], ID_STUDENT [Tên sinh viên] ,[Ngày hết hạn] = ( day(7*BORROW_TIME) + (TIME_CREATE))	
	FROM BORROW A, BORROW_DETAIL B
	WHERE A.ID = B.ID
	GROUP BY a.ID, ID_STUDENT, ( day(7*BORROW_TIME) + (TIME_CREATE))	
----------------------------------------------------------------------------------------------------------------------DATA----------------------------------------------------------------------------------------------------------------------------------------------------------------