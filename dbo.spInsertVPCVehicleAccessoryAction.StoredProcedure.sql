USE [Daidb]
GO
/****** Object:  StoredProcedure [dbo].[spInsertVPCVehicleAccessoryAction]    Script Date: 4/21/2017 3:51:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[spInsertVPCVehicleAccessoryAction](
	@VINKey			varchar(8),
	 @AccessoryCode		varchar(8),
	 @CompletedDate		datetime,
	 @CompletedBy		varchar(20),
	 @CreatedBy		varchar(20)
	)
AS
BEGIN
	/*******************************************************************************
	*	spInsertVPCVehicleAccessoryAction					*
	*										*
	*	Description								*
	*	----------								*
	*	Insert the Accessory in VPCVehicleAccessoryAction Table			*
	*										*
	*										*
	* 	Change History								*
	* 	--------------								*
	* 	Date       Init's Description						*
	* 	---------- ------ ----------------------------------------		*
	* 	06/07/2013 SS-CMK    Initial version					*
	* 	10/014/2013 SS-     Modified version to handle duplicate vin keys	*
	*	Also replace Criterion for VIN Key to VPCVehicleID as it is unique	*
	*										*
	*	1-No VIN attached to VPC vehicle table					*
	*	(Also VIN key is not duplicate in vpc vehicle table)			*
	*	2-Shop Work Not started yet	(Disable for time being)		*
	*	3-No Accessory Code attached in master table				*
	*	4-Duplicate Accessory Entered in Action table				*
	*	5-Get payrate from master table						*
											*
	*********************************************************************************/
 	SET nocount on

	DECLARE @Status			varchar(20),
		@VehicleStatus		varchar(20),
		@VPCVehicleID		int,
		@VMSCarAccessoryID	int,
		@ShopWorkStartedInd	int,
		@DiversifiedPieceRate	decimal(16,2),
		@PayAtPDIRateInd	int,
		@EmployeeName		varchar(100),
		@CompletedDateOn	varchar(100),
		@ReturnCode		int,
		@ReturnMessage		varchar(100),
		@ErrorID		int,
		@Msg			varchar(100),
		@Count			int
		
 	SELECT @Count =0
 	SELECT @ErrorID =0

	BEGIN TRAN

	IF DATALENGTH(@VINKey)<1
		BEGIN
		SELECT @ErrorID = 100000
		SELECT @Msg = 'No VIN Key Entered.'
		GOTO Error_Encountered
	END

	SELECT @Count = NULL

	SELECT TOP 1 @VPCVehicleID=VPCV.VPCVehicleID,@ShopWorkStartedInd = ISNULL(ShopWorkStartedInd,0)
	FROM VPCVehicle VPCV    
	WHERE VPCV.VINKEY =@VINKey
	ORDER BY ReleaseDate Desc

	IF @@ERROR <> 0
		BEGIN
		SELECT @ErrorID = @@ERROR
		SELECT @Msg = 'Error Number '+CONVERT(varchar(10),@ErrorID)+' encountered getting the VIN '
		GOTO Error_Encountered
	END    

	IF @VPCVehicleID IS NULL
		---OR @Count = 0
		BEGIN
		SELECT @ErrorID = 100003
		SELECT @Msg = 'VIN not found in VPC Vehicles table'
		GOTO Error_Encountered
	END


	-------Time being disable october 14, 2013
	--IF @ShopWorkStartedInd = 0
	--BEGIN
	--SELECT @ErrorID = 100004
	--Accessory throw in not done yet
	--SELECT @Msg = 'Shop Work not started yet'
	--GOTO Error_Encountered
	--END


	SELECT @Count = NULL


	SELECT @Count =Count(VPAC.AccessoryCode)
	FROM VPCVehicleAccessory VPAC    
	LEFT JOIN VPCVehicle VPCV ON VPAC.VPCVehicleID = VPCV.VPCVehicleID
	LEFT JOIN VPCAccessoryMaster VPAM ON (SELECT TOP 1 VAM2.VPCAccessoryMasterID
	FROM VPCAccessoryMaster VAM2 WHERE VPAC.AccessoryCode = VAM2.AccessoryCode
	AND (VPCV.VehicleYear = VAM2.VehicleYear OR VAM2.VehicleYear IS NULL)
	AND (VPCV.CarLineTitle = VAM2.CarLineTitle OR VAM2.CarLineTitle IS NULL)
	AND VPAC.VMSCarAccessoryID = VAM2.VMSCarAccessoryID
	ORDER BY
	CASE WHEN VAM2.VehicleYear IS NOT NULL AND VAM2.CarLineTitle IS NOT NULL THEN 4
	WHEN VAM2.VehicleYear IS NULL AND VAM2.CarLineTitle IS NOT NULL THEN 3
	WHEN VAM2.VehicleYear IS NOT NULL AND VAM2.CarLineTitle IS NULL THEN 2
	WHEN VAM2.VehicleYear IS NULL AND VAM2.CarLineTitle IS NULL THEN 1
	ELSE 0 END Desc) = VPAM.VPCAccessoryMasterID
	WHERE    
	---VPCV.VINKey = @VINKey
	VPCV.VPCVehicleID=@VPCVehicleID

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrorID = @@ERROR
		SELECT @Msg = 'Error Number '+CONVERT(varchar(10),@ErrorID)+' encountered getting the Accessory Code'
		GOTO Error_Encountered
	END

	IF @Count IS NULL OR @Count = 0
	 BEGIN
		SELECT @ErrorID = 100004
		SELECT @Msg = 'Accessory Code  not found in Master table'
		GOTO Error_Encountered
	END


	SELECT @Count = NULL


	SELECT @Count=Count(VVAA.AccessoryCode)
	--VVA.AccessoryCode,VV.VPCVehicleID,U.EmployeeNumber,U.LastName + ' ' + U.FirstName as EmployeeName,VVA.AccessoryCode,VVAA.CompletedDate as WorkDate,
	--ISNULL(VAM.DiversifiedPieceRate,0) as DiversifiedPieceRate,ISNULL(VAM.AccessoryDescription,'') as AccessoryDescription
	FROM VPCVehicle VV
	LEFT JOIN VPCVehicleAccessory VVA ON VV.VPCVehicleID = VVA.VPCVehicleID
	LEFT JOIN VPCVehicleAccessoryAction VVAA ON VV.VPCVehicleID = VVAA.VPCVehicleID
	AND VVA.AccessoryCode = VVAA.AccessoryCode
	LEFT JOIN Users U ON VVAA.CompletedBy=U.UserCode
	LEFT JOIN VPCAccessoryMaster VAM ON (SELECT TOP 1 VAM2.VPCAccessoryMasterID
	FROM VPCAccessoryMaster VAM2 WHERE VVA.AccessoryCode = VAM2.AccessoryCode
	AND (VV.VehicleYear = VAM2.VehicleYear OR VAM2.VehicleYear IS NULL)
	AND (VV.CarLineTitle = VAM2.CarLineTitle OR VAM2.CarLineTitle IS NULL)
	AND VVA.VMSCarAccessoryID = VAM2.VMSCarAccessoryID
	AND ISNULL(VVAA.CompletedDate,VV.ReleaseDate) BETWEEN VAM2.EffectiveDate AND ISNULL(VAM2.ExpirationDate, '2999-01-01 00:00:00.000')
	ORDER BY CASE WHEN VAM2.VehicleYear IS NOT NULL AND VAM2.CarLineTitle IS NOT NULL THEN 4
	WHEN VAM2.VehicleYear IS NULL AND VAM2.CarLineTitle IS NOT NULL THEN 3
	WHEN VAM2.VehicleYear IS NOT NULL AND VAM2.CarLineTitle IS NULL THEN 2
	WHEN VAM2.VehicleYear IS NULL AND VAM2.CarLineTitle IS NULL THEN 1
	ELSE 0 END DESC) = VAM.VPCAccessoryMasterID
	WHERE 
	----VV.VINKey =@VINKey
	VV.VPCVehicleID=@VPCVehicleID
	AND VVA.AccessoryCode = @AccessoryCode


	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrorID = @@ERROR
		SELECT @Msg = 'Error Number '+CONVERT(varchar(10),@ErrorID)+' encountered getting the Accessory Code'
		GOTO Error_Encountered
	END

	IF  @Count > 0	
	BEGIN
	SELECT  @EmployeeName = U.EmployeeNumber + '-'+ U.FirstName+ ' '+ U.LastName,@CompletedDateOn=CONVERT(varchar,CompletedDate, 101)
	FROM VPCVehicle VV  
	LEFT JOIN VPCVehicleAccessory VVA ON VV.VPCVehicleID = VVA.VPCVehicleID
	LEFT JOIN VPCVehicleAccessoryAction VVAA ON VV.VPCVehicleID = VVAA.VPCVehicleID
	AND VVA.AccessoryCode = VVAA.AccessoryCode
	LEFT JOIN Users U ON VVAA.CompletedBy=U.UserCode
	LEFT JOIN VPCAccessoryMaster VAM ON (SELECT TOP 1 VAM2.VPCAccessoryMasterID
	FROM VPCAccessoryMaster VAM2 WHERE VVA.AccessoryCode = VAM2.AccessoryCode
	AND (VV.VehicleYear = VAM2.VehicleYear OR VAM2.VehicleYear IS NULL)
	AND (VV.CarLineTitle = VAM2.CarLineTitle OR VAM2.CarLineTitle IS NULL)
	AND VVA.VMSCarAccessoryID = VAM2.VMSCarAccessoryID
	AND ISNULL(VVAA.CompletedDate,VV.ReleaseDate) BETWEEN VAM2.EffectiveDate AND ISNULL(VAM2.ExpirationDate, '2999-01-01 00:00:00.000')
	ORDER BY CASE WHEN VAM2.VehicleYear IS NOT NULL AND VAM2.CarLineTitle IS NOT NULL THEN 4
	WHEN VAM2.VehicleYear IS NULL AND VAM2.CarLineTitle IS NOT NULL THEN 3
	WHEN VAM2.VehicleYear IS NOT NULL AND VAM2.CarLineTitle IS NULL THEN 2
	WHEN VAM2.VehicleYear IS NULL AND VAM2.CarLineTitle IS NULL THEN 1
	ELSE 0 END DESC) = VAM.VPCAccessoryMasterID
	WHERE 
	----VV.VINKey =@VINKey
	VV.VPCVehicleID=@VPCVehicleID
	AND VVA.AccessoryCode = @AccessoryCode


		SELECT @ErrorID = 100005
		SELECT @Msg = 'Accessory Code already done By: ' + @EmployeeName +    ' On: ' + @CompletedDateOn
		GOTO Error_Encountered
	END


	SELECT @Count = NULL

	----Added Top 1 and removed and added  vpcvehicleID(TOP 1 and Order clause  ORDER BY ShopWorkStartedDate )  October 11 2013 to prevent Duplicate VIN key and piece rates   )

	SELECT @DiversifiedPieceRate=VPAM.DiversifiedPieceRate,@PayAtPDIRateInd =VPAM.PayAtPDIRateInd,@AccessoryCode=VPAM.AccessoryCode,@VMSCarAccessoryID=VPAM.VMSCarAccessoryID
	FROM VPCVehicleAccessory VPAC    
	LEFT JOIN VPCVehicle VPCV ON VPAC.VPCVehicleID = VPCV.VPCVehicleID
	LEFT JOIN VPCAccessoryMaster VPAM ON (SELECT TOP 1 VAM2.VPCAccessoryMasterID
	FROM VPCAccessoryMaster VAM2 WHERE VPAC.AccessoryCode = VAM2.AccessoryCode
	AND (VPCV.VehicleYear = VAM2.VehicleYear OR VAM2.VehicleYear IS NULL)
	AND (VPCV.CarLineTitle = VAM2.CarLineTitle OR VAM2.CarLineTitle IS NULL)
	AND VPAC.VMSCarAccessoryID = VAM2.VMSCarAccessoryID
	ORDER BY
	CASE WHEN VAM2.VehicleYear IS NOT NULL AND VAM2.CarLineTitle IS NOT NULL THEN 4
	WHEN VAM2.VehicleYear IS NULL AND VAM2.CarLineTitle IS NOT NULL THEN 3
	WHEN VAM2.VehicleYear IS NOT NULL AND VAM2.CarLineTitle IS NULL THEN 2
	WHEN VAM2.VehicleYear IS NULL AND VAM2.CarLineTitle IS NULL THEN 1
	ELSE 0 END Desc) = VPAM.VPCAccessoryMasterID
	WHERE
	----VPCV.VINKey = @VINKey
	VPCV.VPCVehicleID=@VPCVehicleID

	AND VPAC.AccessoryCode =@AccessoryCode
	---ORDER BY ShopWorkStartedDate desc

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrorID = @@ERROR
		SELECT @Msg = 'Error Number '+CONVERT(varchar(10),@ErrorID)+' encountered getting the DiversifiedPieceRate'
		GOTO Error_Encountered
	 END

	IF @VMSCarAccessoryID IS NULL
	--OR @Count = 0
	BEGIN
		SELECT @ErrorID = 100008
		SELECT @Msg = 'Accessory Code  not found in Accessory Master table'
		GOTO Error_Encountered
	END



	--Added on May 02, 2014 to validate empty/blank Piece rate

	
	IF @DiversifiedPieceRate IS NULL
	--OR @Count = 0
	BEGIN
		SELECT @ErrorID = 100009
		SELECT @Msg = 'Diversified Piece Rate not found in Accessory Master table'
		GOTO Error_Encountered
	END

	-------

	SELECT @Count = NULL




	INSERT INTO VPCVehicleAccessoryAction(
	VPCVehicleID,
	VMSCarAccessoryID,
	AccessoryCode,
	CompletedInd,
	CompletedDate,
	CompletedBy,
	DiversifiedPieceRate,
	PayAtPDIRateInd,
	PaidInd,
	PaidDate,
	PaidBy,
	VPCPayrollID,
	CreationDate,
	CreatedBy,
	UpdatedDate,
	UpdatedBy)

	VALUES(
	@VPCVehicleID,
	@VMSCarAccessoryID,
	@AccessoryCode,
	1,
	@CompletedDate,
	@CompletedBy,
	@DiversifiedPieceRate,
	@PayAtPDIRateInd,
	0,
	NULL,
	NULL,
	NULL,
	CURRENT_TIMESTAMP,
	@CreatedBy,
	NULL,
	NULL)


	---print 'vpc vehicleid = '+convert(varchar(10),@VPCVehicleID)+','+ 'acc-code= ' + convert(varchar(10),@AccessoryCode)
	--,@CompletedDate,@CompletedBy,@DiversifiedPieceRate

	IF @@Error <> 0
	BEGIN
		SELECT @ErrorID = @@ERROR
		SELECT @Status = 'Error adding Insert Accessory Record'
		GOTO Error_Encountered
	END

	Error_Encountered:
	IF @ErrorID <> 0
	BEGIN
		ROLLBACK TRAN
		SELECT @ReturnCode = @ErrorID
		SELECT @ReturnMessage = @Msg
		GOTO Do_Return
	END
	ELSE
	BEGIN
		COMMIT TRAN
		SELECT @ReturnCode = 0
		SELECT @ReturnMessage = 'Processed'
		GOTO Do_Return
	END

	Do_Return:
	SELECT @ReturnCode AS 'RC', @ReturnMessage AS 'RM',@AccessoryCode AS AccessoryCode,@VMSCarAccessoryID AS VMSCarAccessoryID
	,@DiversifiedPieceRate AS DiversifiedPieceRate,@PayAtPDIRateInd AS PayAtPDIRateInd,@EmployeeName as EmployeeName

	RETURN @ReturnCode

	END
GO
