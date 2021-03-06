USE [Daidb]
GO
/****** Object:  StoredProcedure [dbo].[spGenerateFenkellEPODData]    Script Date: 4/21/2017 3:51:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[spGenerateFenkellEPODData] (@CreatedBy varchar(20))
AS
BEGIN
	set nocount on

	DECLARE
	@ErrorID			int,
	@loopcounter			int,
	--FenkellExportEPOD table variables
	@BatchID			int,
	@CustomerID			int,
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
	@ExportedInd			int,
	@RecordStatus			varchar(100),
	@CreationDate			datetime,
	--processing variables
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
	SELECT @CustomerID = CONVERT(int,ValueDescription)
	FROM SettingTable
	WHERE ValueKey = 'ChryslerCustomerID'
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrorID = @@ERROR
		SELECT @Status = 'Error Getting CustomerID'
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
	--cursor for the pickup records
	DECLARE FenkellEPODCursor CURSOR
	LOCAL FORWARD_ONLY STATIC READ_ONLY
	FOR
		SELECT V.VehicleID, VDD.VehicleDamageDetailID, L.RunID, U.FirstName+' '+U.LastName DriverName, T.TruckNumber, T2.TrailerNumber,
		CASE WHEN L3.ParentRecordTable = 'Common' THEN (SELECT Value2 FROM Code WHERE CodeType = 'VistaLocationCode'
		AND Value1 = CONVERT(varchar(10),L3.LocationID)) ELSE L3.SPLCCode END OriginCode,
		CASE WHEN L4.ParentRecordTable = 'Common' THEN (SELECT Value2 FROM Code WHERE CodeType = 'VistaLocationCode'
		AND Value1 = CONVERT(varchar(10),L4.LocationID)) ELSE L4.CustomerLocationCode END DestinationCode,
		L.PickupDate, L5.DropoffDate, '' SpecialInstructions, '' DeliveryReceiptReferenceID, '' DeliveryReceiptURL,
		'5' InspectionType, CASE WHEN VI.SubjectToInspectionInd = 1 THEN 'true' ELSE 'false' END SubjectToInspectionFlag,
		'' DealerComment, '' CarrierComment, V.VIN,
		CASE WHEN VDD.DamageCode IS NULL THEN '' ELSE LEFT(VDD.DamageCode, 2) END,
		CASE WHEN VDD.DamageCode IS NULL THEN '' ELSE SUBSTRING(VDD.DamageCode,3,2) END,
		CASE WHEN VDD.DamageCode IS NULL THEN '' ELSE RIGHT(VDD.DamageCode,1) END,
		'' DamageComment, '' PhotoReferenceID, '' PhotoURL
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
		---LEFT JOIN Run R ON L2.RunID = R.RunID (Change on 05/27/2015 to avoid 
		LEFT JOIN Run R ON L.RunID = R.RunID
		LEFT JOIN Truck T ON R.TruckID = T.TruckID
		AND T.TruckNumber <> '001'
		LEFT JOIN Trailer T2 ON T.CurrentTrailerID = T2.TrailerID
		WHERE V.CustomerID = @CustomerID
		AND V.VehicleStatus = 'Delivered'
		--AND L5.DropoffDate >= '09/01/2015'	--use cutoff date for new program
		AND L5.DropoffDate > DATEADD(day,-360,CURRENT_TIMESTAMP) --MINUS 1 YEAR IS REAL VALUE

		--AND L5.DropoffDate >= '10/03/2013'	--use cutoff date for new program (get 111 records for testing)
		AND (V.VehicleID NOT IN (SELECT FE.VehicleID FROM FenkellExportEPOD FE)
		OR (VDD.VehicleDamageDetailID IS NOT NULL AND VDD.VehicleDamageDetailID NOT IN (SELECT DISTINCT FE.VehicleDamageDetailID FROM FenkellExportEPOD FE WHERE FE.VehicleID = V.VehicleID AND FE.VehicleDamageDetailID IS NOT NULL)))
		ORDER BY L2.LoadNumber, V.VehicleID, VDD.DamageCode
	--print 'cursor declared'
	SELECT @ErrorID = 0
	SELECT @loopcounter = 0
	
	OPEN FenkellEPODCursor
	--print 'cursor opened'
	BEGIN TRAN
	--print 'tran started'
	--set the next batch id in the setting table
	
	UPDATE SettingTable
	SET ValueDescription = @BatchID+1	
	WHERE ValueKey = 'NextFenkellExportEPODBatchID'
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrorID = @@ERROR
		SELECT @Status = 'Error Setting BatchID'
		GOTO Error_Encountered
	END
	
	--print 'batch id updated'
	--set the default values
	SELECT @CarrierCode = 'DVAI' --'58792'
	SELECT @ExportedInd = 0
	SELECT @RecordStatus = 'Export Pending'
	SELECT @CreationDate = CURRENT_TIMESTAMP
	--print 'default values set'
	
	FETCH FenkellEPODCursor INTO @VehicleID, @VehicleDamageDetailID, @RunID, @DriverName,
		@TruckNumber, @TrailerNumber, @OriginCode, @DestinationCode, @DepartureDateTime,
		@DeliveryDateTime, @SpecialInstructions, @DeliveryReceiptReferenceID, @DeliveryReceiptURL,
		@InspectionType, @SubjectToInspectionFlag, @DealerComment, @CarrierComment, @VIN,
		@DamageAreaCode, @DamageTypeCode, @DamageSeverityCode, @DamageComment,
		@PhotoReferenceID, @PhotoURL
	
	--print 'about to enter loop'
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO FenkellExportEPOD(
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
			CreationDate
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
			@CreationDate
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
			@PhotoReferenceID, @PhotoURL

	END --end of loop
	
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
