USE [Daidb]
GO
/****** Object:  StoredProcedure [dbo].[TestspGenerateFenkellEPODData]    Script Date: 4/21/2017 3:51:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[TestspGenerateFenkellEPODData] (@CustomerID int, @CreatedBy varchar(20))
AS
BEGIN
	set nocount on

	DECLARE
	@ErrorID			int,
	@loopcounter			int,
	--FenkellExportEPOD table variables
	@BatchID			int,
	@VehicleID			int,
	@VehicleDamageDetailID		int,
	@RunID				int,
	@CarrierCode			varchar(15),
	@DriverName			varchar(60),
	@TruckNumber			varchar(20),
	@TrailerNumber			varchar(20),
	@OriginCode			varchar(20),
	@DestinationCode		varchar(20),
	@DepartureDateTime		datetime,
	@DeliveryDateTime		datetime,
	@SpecialInstructions		varchar(100),
	@DeliveryReceiptReferenceID	varchar(20),
	@DeliveryReceiptURL		varchar(255),
	@InspectionType			varchar(2),
	@SubjectToInspectionFlag	varchar(5),
	@DealerComment			varchar(100),
	@CarrierComment			varchar(100),
	@VIN				varchar(17),
	@DamageAreaCode			varchar(2),
	@DamageTypeCode			varchar(2),
	@DamageSeverityCode		varchar(1),
	@DamageComment			varchar(100),
	@PhotoReferenceID		varchar(20),
	@PhotoURL			varchar(255),
	@DamagePhotoCount		int,
	@RunCreationDate		datetime,
	@ExportedInd			int,
	@RecordStatus			varchar(100),
	@CreationDate			datetime,
	--processing variables
	@SCACCode			varchar(15),
	@ChryslerCustomerID		int,
	@VolkswagenCustomerID		int,
	@Status				varchar(100),
	@ReturnCode			int,
	@ReturnMessage			varchar(100)

	/************************************************************************
	*	spGenerateFenkellEPODData					*
	*									*
	*	Description							*
	*	-----------							*
	*	This procedure generates the Fenkell EPOD export data for	*
	*	vehicles that have been delivered inspected.			*
	*									*
	*	Change History							*
	*	--------------							*
	*	Date       Init's Description					*
	*	---------- ------ ----------------------------------------	*
	*	04/24/2014 CMK    Initial version				*
	*									*
	************************************************************************/
	
	--get the ChryslerCustomerID
	SELECT @ChryslerCustomerID = CONVERT(int,ValueDescription)
	FROM SettingTable
	WHERE ValueKey = 'ChryslerCustomerID'
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrorID = @@ERROR
		SELECT @Status = 'Error Getting ChryslerCustomerID'
		GOTO Error_Encountered2
	END
	IF @ChryslerCustomerID IS NULL
	BEGIN
		SELECT @ErrorID = 100000
		SELECT @Status = 'ChryslerCustomerID Not Found'
		GOTO Error_Encountered2
	END
	
	--get the VolkswagenCustomerID
	SELECT @VolkswagenCustomerID = CONVERT(int,ValueDescription)
	FROM SettingTable
	WHERE ValueKey = 'VolkswagenCustomerID'
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrorID = @@ERROR
		SELECT @Status = 'Error Getting VolkswagenCustomerID'
		GOTO Error_Encountered2
	END
	IF @VolkswagenCustomerID IS NULL
	BEGIN
		SELECT @ErrorID = 100000
		SELECT @Status = 'VolkswagenCustomerID Not Found'
		GOTO Error_Encountered2
	END
	
	--get the next batch id from the setting table
	--print 'getting batch id'
	Select @BatchID = CONVERT(int,ValueDescription)
	FROM SettingTable
	WHERE ValueKey = 'NextFenkellExportEPODBatchID'
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrorID = @@ERROR
		SELECT @Status = 'Error Getting BatchID'
		GOTO Error_Encountered2
	END
	IF @BatchID IS NULL
	BEGIN
		SELECT @ErrorID = 100001
		SELECT @Status = 'BatchID Not Found'
		GOTO Error_Encountered2
	END
	--print 'have batch id'
	
	SELECT TOP 1 @SCACCode = Value1
	FROM Code
	WHERE CodeType = 'FenkellCustomerCode'
	AND Code = CONVERT(varchar(20),@CustomerID)
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrorID = @@ERROR
		SELECT @Status = 'Error Getting SCACCode'
		GOTO Error_Encountered2
	END
	IF @SCACCode IS NULL
	BEGIN
		SELECT @ErrorID = 100002
		SELECT @Status = 'SCACCode Not Found'
		GOTO Error_Encountered2
	END



	UPDATE SettingTable
	SET ValueDescription = @BatchID+1	
	WHERE ValueKey = 'NextFenkellExportEPODBatchID'
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrorID = @@ERROR
		SELECT @Status = 'Error Setting BatchID'
		GOTO Error_Encountered2
	END
	IF @BatchID IS NULL
	BEGIN
		SELECT @ErrorID = 100001
		SELECT @Status = 'BatchID Not Found'
		GOTO Error_Encountered2
	END
	

--Select Code,CodeDescription from Code Where Codetype ='FenkellCustomerCode'
--Declare @customerid int,@ChryslerCustomerID int,@VolkswagenCustomerID int
--Set @Customerid =5923
--Set @ChryslerCustomerID =5923
--Set @VolkswagenCustomerID =6404

--New Cursor for the pickup records/Loading inspection
DECLARE FenkellEPODCursor CURSOR
	LOCAL FORWARD_ONLY STATIC READ_ONLY
	FOR
		SELECT V.VehicleID, VDD.VehicleDamageDetailID, L.RunID, U.FirstName+' '+U.LastName DriverName, T.TruckNumber, T2.TrailerNumber,

		CASE WHEN @CustomerID = @ChryslerCustomerID THEN
			CASE WHEN L3.ParentRecordTable = 'Common' THEN (SELECT Value2 FROM Code WHERE CodeType = 'VistaLocationCode'
			AND Value1 = CONVERT(varchar(10),L3.LocationID)) ELSE L3.SPLCCode END
		WHEN @CustomerID = @VolkswagenCustomerID THEN
			CASE WHEN L3.ParentRecordTable = 'Common' THEN (SELECT C.Code FROM Code C WHERE C.CodeType = 'ICL'+(SELECT C2.Code FROM Code C2 WHERE C2.CodeType = 'ICLCustomerCode' AND C2.Value1 = CONVERT(varchar(10),@CustomerID))+'LocationCode'
			AND C.Value1 = CONVERT(varchar(10),V.PickupLocationID))
			WHEN DATALENGTH(L3.CustomerLocationCode) > 0 THEN L3.CustomerLocationCode
			ELSE LEFT(L3.Zip,5) END
		END OriginCode,
				
		CASE WHEN @CustomerID = @ChryslerCustomerID THEN
			CASE WHEN L4.ParentRecordTable = 'Common' THEN (SELECT Value2 FROM Code WHERE CodeType = 'VistaLocationCode'
			AND Value1 = CONVERT(varchar(10),L4.LocationID)) ELSE L4.CustomerLocationCode END
		WHEN @CustomerID = @VolkswagenCustomerID THEN
			CASE WHEN L4.ParentRecordTable = 'Common' THEN (SELECT C.Code FROM Code C WHERE C.CodeType = 'ICL'+(SELECT C2.Code FROM Code C2 WHERE C2.CodeType = 'ICLCustomerCode' AND C2.Value1 = CONVERT(varchar(10),@CustomerID))+'LocationCode'
			AND C.Value1 = CONVERT(varchar(10),V.DropoffLocationID))
			WHEN DATALENGTH(L4.CustomerLocationCode) > 0 THEN L4.CustomerLocationCode
			ELSE LEFT(L4.Zip,5) END
		END DestinationCode,
		
		L.PickupDate,ISNULL(L5.DropoffDate,Null) as DropoffDate, '' SpecialInstructions, '' DeliveryReceiptReferenceID, '' DeliveryReceiptURL,
		'2' InspectionType,'False' SubjectToInspectionFlag,
		'' DealerComment, '' CarrierComment, V.VIN,
		CASE WHEN VDD.DamageCode IS NULL THEN '' ELSE LEFT(VDD.DamageCode, 2) END,
		CASE WHEN VDD.DamageCode IS NULL THEN '' ELSE SUBSTRING(VDD.DamageCode,3,2) END,
		CASE WHEN VDD.DamageCode IS NULL THEN '' ELSE RIGHT(VDD.DamageCode,1) END,
		'' DamageComment, '' PhotoReferenceID, '' PhotoURL, VDD.DamagePhotoCount,
		R.CreationDate
		FROM Vehicle V
		LEFT JOIN Legs L ON V.VehicleID = L.VehicleID
		AND L.LegNumber = 1
		LEFT JOIN Loads L2 ON L.LoadID = L2.LoadsID
		LEFT JOIN Location L3 ON V.PickupLocationID = L3.LocationID
		LEFT JOIN Location L4 ON V.DropoffLocationID = L4.LocationID
		LEFT JOIN Legs L5 ON V.VehicleID = L5.VehicleID
		AND L5.FinalLegInd = 1
		LEFT JOIN Driver D ON L2.DriverID = D.DriverID
		LEFT JOIN Users U ON D.UserID = U.UserID
		LEFT JOIN VehicleInspection VI ON V.VehicleID = VI.VehicleID
		AND VI.InspectionType IN ('0','1','2')
		LEFT JOIN VehicleDamageDetail VDD ON VI.VehicleInspectionID = VDD.VehicleInspectionID
		LEFT JOIN Run R ON L.RunID = R.RunID
		LEFT JOIN Truck T ON R.TruckID = T.TruckID
		AND T.TruckNumber <> '001'
		LEFT JOIN Trailer T2 ON T.CurrentTrailerID = T2.TrailerID
		WHERE V.CustomerID = @CustomerID
		AND V.VehicleStatus IN ('Enroute','Delivered')
		AND L5.DropoffDate > DATEADD(day,-5,CURRENT_TIMESTAMP) -- per Fenkell, they can take transactions up a year old
		AND (V.VehicleID NOT IN (SELECT FE.VehicleID FROM TestFenkellExportEPOD FE WHERE FE.VehicleID = V.VehicleID  AND FE.Inspectiontype IN ('0','1','2'))
		OR (VDD.VehicleDamageDetailID IS NOT NULL AND VDD.VehicleDamageDetailID NOT IN 
		(SELECT DISTINCT FE.VehicleDamageDetailID FROM TestFenkellExportEPOD FE WHERE FE.VehicleID = V.VehicleID AND FE.VehicleDamageDetailID IS NOT NULL)))
		ORDER BY L2.LoadNumber, V.VehicleID, VDD.DamageCode




	



--print 'cursor declared'
	SELECT @ErrorID = 0
	SELECT @loopcounter = 0
	
	OPEN FenkellEPODCursor
	--print 'cursor opened'
	BEGIN TRAN
	--print 'tran started'
	--set the next batch id in the setting table
	--move it to up
	
	--print 'batch id updated'
	--set the default values
	SELECT @CarrierCode = @SCACCode
	SELECT @ExportedInd = 0
	SELECT @RecordStatus = 'Export Pending'
	SELECT @CreationDate = CURRENT_TIMESTAMP
	--print 'default values set'
	
	FETCH FenkellEPODCursor INTO @VehicleID, @VehicleDamageDetailID, @RunID, @DriverName,
		@TruckNumber, @TrailerNumber, @OriginCode, @DestinationCode, @DepartureDateTime,
		@DeliveryDateTime, @SpecialInstructions, @DeliveryReceiptReferenceID, @DeliveryReceiptURL,
		@InspectionType, @SubjectToInspectionFlag, @DealerComment, @CarrierComment, @VIN,
		@DamageAreaCode, @DamageTypeCode, @DamageSeverityCode, @DamageComment,
		@PhotoReferenceID, @PhotoURL, @DamagePhotoCount, @RunCreationDate
	
	--print 'about to enter loop'
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO TestFenkellExportEPOD(
			BatchID,
			CustomerID,
			VehicleID,
			VehicleDamageDetailID,
			RunID,
			CarrierCode,
			DriverName,
			TruckNumber,
			TrailerNumber,
			OriginCode,
			DestinationCode,
			DepartureDateTime,
			DeliveryDateTime,
			SpecialInstructions,
			DeliveryReceiptReferenceID,
			DeliveryReceiptURL,
			InspectionType,
			SubjectToInspectionFlag,
			DealerComment,
			CarrierComment,
			VIN,
			DamageAreaCode,
			DamageTypeCode,
			DamageSeverityCode,
			DamageComment,
			PhotoReferenceID,
			PhotoURL,
			ExportedInd,
			RecordStatus,
			CreationDate,
			CreatedBy,
			DamagePhotoCount,
			RunCreationDate
		)
		VALUES(
			@BatchID,
			@CustomerID,
			@VehicleID,
			@VehicleDamageDetailID,
			@RunID,
			@CarrierCode,
			@DriverName,
			@TruckNumber,
			@TrailerNumber,
			@OriginCode,
			--@DestinationCode,
			'',
			@DepartureDateTime,
			--@DeliveryDateTime,
			NULL,
			@SpecialInstructions,
			@DeliveryReceiptReferenceID,
			@DeliveryReceiptURL,
			@InspectionType,
			@SubjectToInspectionFlag,
			@DealerComment,
			@CarrierComment,
			@VIN,
			@DamageAreaCode,
			@DamageTypeCode,
			@DamageSeverityCode,
			@DamageComment,
			@PhotoReferenceID,
			@PhotoURL,
			@ExportedInd,
			@RecordStatus,
			@CreationDate,
			@CreatedBy,
			@DamagePhotoCount,
			@RunCreationDate
		)
		IF @@Error <> 0
		BEGIN
			SELECT @ErrorID = @@ERROR
			SELECT @Status = 'Error creating Fenkell EPOD record'
			GOTO Error_Encountered
		END
			
		FETCH FenkellEPODCursor INTO @VehicleID, @VehicleDamageDetailID, @RunID, @DriverName,
			@TruckNumber, @TrailerNumber, @OriginCode, @DestinationCode, @DepartureDateTime,
			@DeliveryDateTime, @SpecialInstructions, @DeliveryReceiptReferenceID, @DeliveryReceiptURL,
			@InspectionType, @SubjectToInspectionFlag, @DealerComment, @CarrierComment, @VIN,
			@DamageAreaCode, @DamageTypeCode, @DamageSeverityCode, @DamageComment,
			@PhotoReferenceID, @PhotoURL, @DamagePhotoCount, @RunCreationDate





	END --end of loop


		
		CLOSE FenkellEPODCursor
		DEALLOCATE FenkellEPODCursor
	
	--print '2nd cursor for the Delivery'



	--print 'test1'
	

--Declare @customerid int,@ChryslerCustomerID int,@VolkswagenCustomerID int
--Set @Customerid =5923
---Set @ChryslerCustomerID =5923
--Set @VolkswagenCustomerID =6404

	DECLARE FenkellEPODCursor CURSOR
	LOCAL FORWARD_ONLY STATIC READ_ONLY
	FOR
		SELECT V.VehicleID, VDD.VehicleDamageDetailID, L.RunID, U.FirstName+' '+U.LastName DriverName, T.TruckNumber, T2.TrailerNumber,

		CASE WHEN @CustomerID = @ChryslerCustomerID THEN
			CASE WHEN L3.ParentRecordTable = 'Common' THEN (SELECT Value2 FROM Code WHERE CodeType = 'VistaLocationCode'
			AND Value1 = CONVERT(varchar(10),L3.LocationID)) ELSE L3.SPLCCode END
		WHEN @CustomerID = @VolkswagenCustomerID THEN
			CASE WHEN L3.ParentRecordTable = 'Common' THEN (SELECT C.Code FROM Code C WHERE C.CodeType = 'ICL'+(SELECT C2.Code FROM Code C2 WHERE C2.CodeType = 'ICLCustomerCode' AND C2.Value1 = CONVERT(varchar(10),@CustomerID))+'LocationCode'
			AND C.Value1 = CONVERT(varchar(10),V.PickupLocationID))
			WHEN DATALENGTH(L3.CustomerLocationCode) > 0 THEN L3.CustomerLocationCode
			ELSE LEFT(L3.Zip,5) END
		END OriginCode,
				
		CASE WHEN @CustomerID = @ChryslerCustomerID THEN
			CASE WHEN L4.ParentRecordTable = 'Common' THEN (SELECT Value2 FROM Code WHERE CodeType = 'VistaLocationCode'
			AND Value1 = CONVERT(varchar(10),L4.LocationID)) ELSE L4.CustomerLocationCode END
		WHEN @CustomerID = @VolkswagenCustomerID THEN
			CASE WHEN L4.ParentRecordTable = 'Common' THEN (SELECT C.Code FROM Code C WHERE C.CodeType = 'ICL'+(SELECT C2.Code FROM Code C2 WHERE C2.CodeType = 'ICLCustomerCode' AND C2.Value1 = CONVERT(varchar(10),@CustomerID))+'LocationCode'
			AND C.Value1 = CONVERT(varchar(10),V.DropoffLocationID))
			WHEN DATALENGTH(L4.CustomerLocationCode) > 0 THEN L4.CustomerLocationCode
			ELSE LEFT(L4.Zip,5) END
		END DestinationCode,
		
		L.PickupDate, L5.DropoffDate, '' SpecialInstructions, '' DeliveryReceiptReferenceID, '' DeliveryReceiptURL,
		CASE WHEN L4.ParentRecordTable = 'Common' THEN '4' ELSE '5' END InspectionType, CASE WHEN VI.SubjectToInspectionInd = 1 THEN 'True' ELSE 'False' END SubjectToInspectionFlag,
		'' DealerComment, '' CarrierComment, V.VIN,
		CASE WHEN VDD.DamageCode IS NULL THEN '' ELSE LEFT(VDD.DamageCode, 2) END,
		CASE WHEN VDD.DamageCode IS NULL THEN '' ELSE SUBSTRING(VDD.DamageCode,3,2) END,
		CASE WHEN VDD.DamageCode IS NULL THEN '' ELSE RIGHT(VDD.DamageCode,1) END,
		'' DamageComment, '' PhotoReferenceID, '' PhotoURL, VDD.DamagePhotoCount,
		R.CreationDate
		FROM Vehicle V
		LEFT JOIN Legs L ON V.VehicleID = L.VehicleID
		AND L.LegNumber = 1
		LEFT JOIN Loads L2 ON L.LoadID = L2.LoadsID
		LEFT JOIN Location L3 ON V.PickupLocationID = L3.LocationID
		LEFT JOIN Location L4 ON V.DropoffLocationID = L4.LocationID
		LEFT JOIN Legs L5 ON V.VehicleID = L5.VehicleID
		AND L5.FinalLegInd = 1
		LEFT JOIN Driver D ON L2.DriverID = D.DriverID
		LEFT JOIN Users U ON D.UserID = U.UserID
		LEFT JOIN VehicleInspection VI ON V.VehicleID = VI.VehicleID
		AND VI.InspectionType = '3'
		LEFT JOIN VehicleDamageDetail VDD ON VI.VehicleInspectionID = VDD.VehicleInspectionID
		LEFT JOIN Run R ON L.RunID = R.RunID
		LEFT JOIN Truck T ON R.TruckID = T.TruckID
		AND T.TruckNumber <> '001'
		LEFT JOIN Trailer T2 ON T.CurrentTrailerID = T2.TrailerID
		WHERE V.CustomerID = @CustomerID
		AND V.VehicleStatus = 'Delivered'
		AND L5.DropoffDate > DATEADD(day,-5,CURRENT_TIMESTAMP) -- per Fenkell, they can take transactions up a year old
		AND (V.VehicleID NOT IN (SELECT FE.VehicleID FROM TestFenkellExportEPOD FE WHERE FE.VehicleID = V.VehicleID  AND FE.Inspectiontype IN('5','4'))
		OR (VDD.VehicleDamageDetailID IS NOT NULL AND VDD.VehicleDamageDetailID NOT IN (SELECT DISTINCT FE.VehicleDamageDetailID FROM TestFenkellExportEPOD FE WHERE FE.VehicleID = V.VehicleID AND FE.VehicleDamageDetailID IS NOT NULL)))
		ORDER BY L2.LoadNumber, V.VehicleID, VDD.DamageCode
	--print 'cursor declared'
	SELECT @ErrorID = 0
	SELECT @loopcounter = 0
	
	OPEN FenkellEPODCursor
	--print 'cursor opened'
	--BEGIN TRAN
	--print 'tran started'
	--set the next batch id in the setting table
	--move it to up
	
	--print 'batch id updated'
	--set the default values
	SELECT @CarrierCode = @SCACCode
	SELECT @ExportedInd = 0
	SELECT @RecordStatus = 'Export Pending'
	SELECT @CreationDate = CURRENT_TIMESTAMP
	--print 'default values set'
	
	FETCH FenkellEPODCursor INTO @VehicleID, @VehicleDamageDetailID, @RunID, @DriverName,
		@TruckNumber, @TrailerNumber, @OriginCode, @DestinationCode, @DepartureDateTime,
		@DeliveryDateTime, @SpecialInstructions, @DeliveryReceiptReferenceID, @DeliveryReceiptURL,
		@InspectionType, @SubjectToInspectionFlag, @DealerComment, @CarrierComment, @VIN,
		@DamageAreaCode, @DamageTypeCode, @DamageSeverityCode, @DamageComment,
		@PhotoReferenceID, @PhotoURL, @DamagePhotoCount, @RunCreationDate
	
	--print 'about to enter loop'
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO TestFenkellExportEPOD(
			BatchID,
			CustomerID,
			VehicleID,
			VehicleDamageDetailID,
			RunID,
			CarrierCode,
			DriverName,
			TruckNumber,
			TrailerNumber,
			OriginCode,
			DestinationCode,
			DepartureDateTime,
			DeliveryDateTime,
			SpecialInstructions,
			DeliveryReceiptReferenceID,
			DeliveryReceiptURL,
			InspectionType,
			SubjectToInspectionFlag,
			DealerComment,
			CarrierComment,
			VIN,
			DamageAreaCode,
			DamageTypeCode,
			DamageSeverityCode,
			DamageComment,
			PhotoReferenceID,
			PhotoURL,
			ExportedInd,
			RecordStatus,
			CreationDate,
			CreatedBy,
			DamagePhotoCount,
			RunCreationDate
		)
		VALUES(
			@BatchID,
			@CustomerID,
			@VehicleID,
			@VehicleDamageDetailID,
			@RunID,
			@CarrierCode,
			@DriverName,
			@TruckNumber,
			@TrailerNumber,
			@OriginCode,
			@DestinationCode,
			@DepartureDateTime,
			@DeliveryDateTime,
			@SpecialInstructions,
			@DeliveryReceiptReferenceID,
			@DeliveryReceiptURL,
			@InspectionType,
			@SubjectToInspectionFlag,
			@DealerComment,
			@CarrierComment,
			@VIN,
			@DamageAreaCode,
			@DamageTypeCode,
			@DamageSeverityCode,
			@DamageComment,
			@PhotoReferenceID,
			@PhotoURL,
			@ExportedInd,
			@RecordStatus,
			@CreationDate,
			@CreatedBy,
			@DamagePhotoCount,
			@RunCreationDate
		)
		IF @@Error <> 0
		BEGIN
			SELECT @ErrorID = @@ERROR
			SELECT @Status = 'Error creating Fenkell EPOD record'
			GOTO Error_Encountered
		END
			
		FETCH FenkellEPODCursor INTO @VehicleID, @VehicleDamageDetailID, @RunID, @DriverName,
			@TruckNumber, @TrailerNumber, @OriginCode, @DestinationCode, @DepartureDateTime,
			@DeliveryDateTime, @SpecialInstructions, @DeliveryReceiptReferenceID, @DeliveryReceiptURL,
			@InspectionType, @SubjectToInspectionFlag, @DealerComment, @CarrierComment, @VIN,
			@DamageAreaCode, @DamageTypeCode, @DamageSeverityCode, @DamageComment,
			@PhotoReferenceID, @PhotoURL, @DamagePhotoCount, @RunCreationDate

	END --end of loop
	
	
	print @CustomerID

	--print 'end of loop'
	Error_Encountered:
	
	IF @ErrorID = 0
	BEGIN
		COMMIT TRAN
		CLOSE FenkellEPODCursor
		DEALLOCATE FenkellEPODCursor
		SELECT @ReturnCode = 0
		SELECT @ReturnMessage = 'Processing Completed Successfully'
		GOTO Do_Return
	END
	ELSE
	BEGIN
		ROLLBACK TRAN
		CLOSE FenkellEPODCursor
		DEALLOCATE FenkellEPODCursor
		SELECT @ReturnCode = @ErrorID
		SELECT @ReturnMessage = @Status
		GOTO Do_Return
	END
	
	Error_Encountered2:
	
	IF @ErrorID = 0
	BEGIN
		SELECT @ReturnCode = 0
		SELECT @ReturnMessage = 'Processing Completed Successfully'
		GOTO Do_Return
	END
	ELSE
	BEGIN
		SELECT @ReturnCode = @ErrorID
		SELECT @ReturnMessage = @Status
		GOTO Do_Return
	END
	
	Do_Return:
	SELECT @ReturnCode AS ReturnCode, @ReturnMessage AS ReturnMessage, @BatchID AS BatchID
	
	RETURN
END

GO
