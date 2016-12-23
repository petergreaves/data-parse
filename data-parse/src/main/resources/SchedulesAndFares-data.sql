PRINT N'Refreshing GD T1 stored procedures...'
USE ejFlight;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF EXISTS
    (
        SELECT  *
        FROM    sys.sysobjects
        WHERE
            id                                 = OBJECT_ID(N'[dbo].[CreateFlightScheduleWithCapacity]')
          AND
            OBJECTPROPERTY(id, N'IsProcedure') = 1
    )
    BEGIN
        DROP PROCEDURE dbo.CreateFlightScheduleWithCapacity;
    END;
GO

CREATE PROCEDURE dbo.CreateFlightScheduleWithCapacity
    @AircraftType       VARCHAR(10)
  , @CarrierCode        VARCHAR(3)
  , @FlightNumber       VARCHAR(10)
  , @LocalDepDtTm       DATETIME
  , @LocalArrDtTm       DATETIME
  , @DepAirportCode     VARCHAR(3)
  , @ArrAirportCode     VARCHAR(3)
  , @SeatsSold          INT
  , @CheckInStatus      VARCHAR(2)
  , @DepTerminalCode    VARCHAR(10)
  , @ArrTerminalCode    VARCHAR(10)
  , @PostedToAccounting VARCHAR(1)
  , @Capacity           INT = NULL
  , @Lid                INT = NULL
AS
    BEGIN
        -- Declare & set local lookup variables
        DECLARE @FlightKey VARCHAR(18);
        SET @FlightKey = FORMAT(@LocalDepDtTm, 'yyyyMMdd') + @DepAirportCode + @ArrAirportCode + RIGHT('    ' + RTRIM(CAST(@FlightNumber AS CHAR(4))), 4);

        DECLARE @SellableLid INT;
        SELECT  @SellableLid = ISNULL(@Lid, SellableLid)
        FROM    dbo.Equipment
        WHERE   AircraftType = @AircraftType;

        DECLARE @MaxSeats INT;
        SELECT  @MaxSeats = ISNULL(@Capacity, MaxSeats)
        FROM    dbo.Equipment
        WHERE   AircraftType = @AircraftType;

        DECLARE @FlightId INT;
        SELECT  @FlightId = FlightId FROM dbo.Flight F WHERE  F.FlightKey = @FlightKey

        -- Confirm non-existence before inserting
        IF @FlightId IS NULL
            BEGIN
                SELECT @FlightId = ISNULL(MAX(FlightID), 0) + 1 FROM ejFlight.dbo.Flight WITH ( UPDLOCK )

                INSERT INTO dbo.Flight
                    (
                        FlightID
                      , EquipmentID
                      , FlightKey
                      , CarrierCode
                      , FlightNumber
                      , LocalDepTm
                      , LocalArrTm
                      , DepAirportCodeID
                      , LocalDepDt
                      , ArrAirportCodeID
                      , Capacity
                      , KiloDistance
                      , SeatsSold
                      , Lid
                      , CheckInStatus
                      , LockKey
                      , TailNumber
                      , PostedToAccountingFlag
                      , FVarbinary
                      , LocalDepDtTm
                      , LocalArrDtTm
                      , AircraftNum
                      , SeasonCodeID
                      , IROP_Lid
                      , DepTerminalCodeID
                      , ArrTerminalCodeID
                      , SBCount
                      , SBSold
                      , LastUpdated
                    )
                VALUES
                    (
                        @FlightId
                      , (
                            SELECT      EquipmentID FROM    dbo.Equipment WHERE AircraftType = @AircraftType
                        )
                      , @FlightKey
                      , @CarrierCode
                      , @FlightNumber
                      , FORMAT(@LocalDepDtTm, 'HHmm')
                      , FORMAT(@LocalArrDtTm, 'HHmm')
                      , (
                            SELECT  AirportCodeID FROM  dbo.AirportCode WHERE   AirportCode = @DepAirportCode
                        )
                      , CAST(@LocalDepDtTm AS DATE)
                      , (
                            SELECT  AirportCodeID FROM  dbo.AirportCode WHERE   AirportCode = @ArrAirportCode
                        )
                      , @MaxSeats
                      , NULL
                      , @SeatsSold
                      , @SellableLid
                      , @CheckInStatus
                      , 0
                      , NULL
                      , @PostedToAccounting
                      , NULL
                      , @LocalDepDtTm
                      , @LocalArrDtTm
                      , 1
                      , 29
                      , (
                            SELECT  SellableLid FROM    dbo.Equipment WHERE AircraftType = @AircraftType
                        )
                      , (
                            SELECT  TerminalCodeID
                            FROM    dbo.TerminalCode
                            WHERE
                                TerminalCode                                                       = @DepTerminalCode
                              AND  AirportCodeID                                                   =
                                (
                                    SELECT  AirportCodeID FROM  dbo.AirportCode WHERE   AirportCode = @DepAirportCode
                                )
                        )
                      , (
                            SELECT  TerminalCodeID
                            FROM    dbo.TerminalCode
                            WHERE
                                TerminalCode                                                      = @ArrTerminalCode
                              AND AirportCodeID                                                   =
                                (
                                    SELECT  AirportCodeID FROM  dbo.AirportCode WHERE   AirportCode = @ArrAirportCode
                                )
                        )
                      , 36
                      , 0
                      , GETDATE()
                    );
            END;
        ELSE
            BEGIN
                UPDATE
                    dbo.Flight
                SET
                    CarrierCode = @CarrierCode
                  , FlightNumber = @FlightNumber
                  , LocalDepTm = FORMAT(@LocalDepDtTm, 'HHmm')
                  , LocalArrTm = FORMAT(@LocalArrDtTm, 'HHmm')
                  , DepAirportCodeID =
                  (
                      SELECT    AirportCodeID FROM  dbo.AirportCode WHERE   AirportCode = @DepAirportCode
                  )
                  , LocalDepDt = CAST(@LocalDepDtTm AS DATE)
                  , ArrAirportCodeID =
                  (
                      SELECT    AirportCodeID FROM  dbo.AirportCode WHERE   AirportCode = @ArrAirportCode
                  )
                  , Capacity = @MaxSeats
                  , KiloDistance = NULL
                  , SeatsSold = @SeatsSold
                  , Lid = @SellableLid
                  , CheckInStatus = @CheckInStatus
                  , LockKey = 0
                  , TailNumber = NULL
                  , PostedToAccountingFlag = @PostedToAccounting
                  , FVarbinary = NULL
                  , LocalDepDtTm = @LocalDepDtTm
                  , LocalArrDtTm = @LocalArrDtTm
                  , AircraftNum = 1
                  , SeasonCodeID = 29
                  , IROP_Lid = @SellableLid
                  , DepTerminalCodeID =
                  (
                      SELECT    TerminalCodeID
                      FROM  dbo.TerminalCode
                      WHERE
                            TerminalCode                                                    = @DepTerminalCode
                        AND AirportCodeID                                                   =
                          (
                              SELECT    AirportCodeID FROM  dbo.AirportCode WHERE   AirportCode = @DepAirportCode
                          )
                  )
                  , ArrTerminalCodeID =
                  (
                      SELECT    TerminalCodeID
                      FROM  dbo.TerminalCode
                      WHERE
                            TerminalCode                                                    = @ArrTerminalCode
                        AND AirportCodeID                                                   =
                          (
                              SELECT    AirportCodeID FROM  dbo.AirportCode WHERE   AirportCode = @ArrAirportCode
                          )
                  )
                  , SBCount = 36
                  , SBSold = 0
                  , LastUpdated = GETDATE()
                WHERE   FlightKey = @FlightKey;
            END;

        IF NOT EXISTS(SELECT * FROM FlightCap WHERE FlightId = @FlightId)
            BEGIN
                INSERT INTO dbo.FlightCap
                    (
                        FlightCapID
                      , FlightID
                      , InfCount
                      , InfSold
                      , HTFCount
                      , HTFSold
                      , HTFConfirmed
                      , HTFPreDepartureDays
                      , HTFSeatsRemaining
                    )
                VALUES
                    (
                        (SELECT ISNULL(MAX(FlightCapID), 0) FROM ejFlight.dbo.FlightCap WITH (UPDLOCK)) + 1
                      , @FlightId
                      , @MaxSeats
                      , 0
                      , NULL
                      , NULL
                      , NULL
                      , NULL
                      , NULL
                    )
            END;
                
        ELSE
            BEGIN
                UPDATE
                    dbo.FlightCap
                SET
                    InfCount = @MaxSeats
                  , InfSold = 0
                  , HTFCount = NULL
                  , HTFSold = NULL
                  , HTFConfirmed = NULL
                  , HTFPreDepartureDays = NULL
                  , HTFSeatsRemaining = NULL
                WHERE
                    FlightId = @FlightId
            END;
    END;

GO
USE ejFlight;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF EXISTS
    (
        SELECT  *
        FROM    sys.sysobjects
        WHERE
            id                                 = OBJECT_ID(N'[dbo].[CreateFlightFareWithFlightKey]')
          AND
            OBJECTPROPERTY(id, N'IsProcedure') = 1
    )
    BEGIN
        DROP PROCEDURE dbo.CreateFlightFareWithFlightKey;
    END;
GO

CREATE PROCEDURE dbo.CreateFlightFareWithFlightKey
    @FareClassCode       VARCHAR(1)
  , @CurrencyCode        VARCHAR(3)
  , @ExtendedPrice       NUMERIC(10, 2)
  , @FlightKey           VARCHAR(18)
  , @SpecialFareCodeDesc VARCHAR(25)
  , @AUmin               INT
  , @AU                  INT
  , @SeatsSold           INT
AS
    BEGIN
        -- Declare & set local lookup variables
        DECLARE @CurrencyCodeId EntityIdentifier;
        DECLARE @FlightId EntityIdentifier;
        DECLARE @SpecialFareId EntityIdentifier;

        DECLARE @FareClassCodeID INT;
        DECLARE @FlightFareId INT;

        SELECT  @CurrencyCodeId = CurrencyCodeID FROM   dbo.CurrencyCode WHERE  CurrencyCode = @CurrencyCode;
        SELECT  @FlightId = FlightID FROM   dbo.Flight WHERE FlightKey = @FlightKey;

        SELECT  @SpecialFareId = SpecialFareID
        FROM    dbo.SpecialFare
        WHERE   SpecialFareCodeID =
            (
                SELECT  SpecialFareCodeID FROM  dbo.SpecialFareCode WHERE   SpecialFareCodeDesc = @SpecialFareCodeDesc
            );

        SELECT
            @FlightFareId = FF.FlightFareID, @FareClassCodeID = FF.FareClassCodeID
        FROM
            dbo.FlightFare FF
        INNER JOIN
            dbo.FareClassCode FCC
                ON FCC.FareClassCode    = @FareClassCode
               AND  FCC.FareClassCodeID = FF.FareClassCodeID
        WHERE   FF.FlightID = @FlightId;

        IF @FlightFareId IS NULL
       AND  @FareClassCodeID IS NULL
            BEGIN
                SET @FareClassCodeID =
                    (
                        SELECT  ISNULL(MAX(FareClassCodeID), 0)
                        FROM    dbo.FareClassCode WITH ( UPDLOCK )
                    ) + 1;
            END;

        -- FareClassCode: Confirm non-existence before inserting.
        IF @FlightFareId IS NULL
            BEGIN
                -- FareClassCode
                INSERT INTO dbo.FareClassCode
                    (
                        FareClassCodeID
                      , FareClassCode
                      , FareClassCodeDescription
                    )
                VALUES
                    (
                        @FareClassCodeID, @FareClassCode, @SpecialFareCodeDesc
                    );
            END;

        -- FlightFare: Confirm non-existence before inserting.
        IF @FlightFareId IS NULL
            BEGIN
                -- FlightFare
                INSERT INTO dbo.FlightFare
                    (
                        FlightFareID
                      , FlightID
                      , SpecialFareID
                      , FareClassCodeID
                      , AUmin
                      , AU
                      , SeatsSold
                    )
                VALUES
                    (
                        (
                            SELECT  ISNULL(MAX(FlightFareID), -1)
                            FROM    dbo.FlightFare WITH ( UPDLOCK )
                        ) + 1
                      , @FlightId
                      , @SpecialFareId
                      , @FareClassCodeID
                      , @AUmin
                      , @AU
                      , @SeatsSold
                    );
            END;
        ELSE
            BEGIN
                UPDATE  dbo.FlightFare
                SET
                    SpecialFareID = @SpecialFareId
                  , AUmin = @AUmin
                  , AU = @AU
                  , SeatsSold = @SeatsSold
                WHERE
                    FlightFareID        = @FlightFareId
                  AND   FlightID        = @FlightId
                  AND   FareClassCodeID = @FareClassCodeID;
            END;

        -- FareClassPriceTranslation: Confirm non-existence before inserting
        IF NOT EXISTS
            (
                SELECT  1
                FROM    dbo.FareClassPriceTranslation FCPT
                WHERE
                    FCPT.FareClassCodeID    = @FareClassCodeID
                  AND   FCPT.CurrencyCodeID = @CurrencyCodeId
            )
            BEGIN
                INSERT INTO dbo.FareClassPriceTranslation
                    (
                        FareClassPriceTranslationID
                      , FareClassCodeID
                      , CurrencyCodeID
                      , ExtendedPrice
                    )
                VALUES
                    (
                        (
                            SELECT  ISNULL(MAX(FareClassPriceTranslationID), 0)
                            FROM    dbo.FareClassPriceTranslation WITH ( UPDLOCK )
                        ) + 1
                      , @FareClassCodeID
                      , @CurrencyCodeId
                      , @ExtendedPrice
                    );
            END;
        ELSE
            BEGIN
                UPDATE  dbo.FareClassPriceTranslation
                SET ExtendedPrice = @ExtendedPrice
                WHERE
                    FareClassCodeID    = @FareClassCodeID
                  AND   CurrencyCodeID = @CurrencyCodeId;
            END;
    END;
GO
USE ejFlight;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF EXISTS
    (
        SELECT  *
        FROM    sys.sysobjects
        WHERE
            id                                 = OBJECT_ID(N'[dbo].[CreateSector]')
          AND
            OBJECTPROPERTY(id, N'IsProcedure') = 1
    )
    BEGIN
        DROP PROCEDURE dbo.CreateSector;
    END;
GO

CREATE PROCEDURE dbo.CreateSector
    @DepAirportCode VARCHAR(3)
  , @ArrAirportCode VARCHAR(3)
  , @ActiveFlag     VARCHAR(1)
  , @Route          VARCHAR(6)
  , @APISFlag       CHAR(1)  = 'Y'
  , @ArrAPISFlag    CHAR(1)  = 'Y'
  , @DepAPISFlag    CHAR(1)  = 'Y'
  , @ICTSFlag       CHAR(1)  = 'Y'
  , @ICTSActiveDate DATETIME = '6 Jul 2016'
AS
    BEGIN

        -- Empty stringReapply default values in parameters containing empty strings

        -- Declare & set local lookup variables
        DECLARE @DepAirportCodeId EntityIdentifier;
        DECLARE @ArrAirportCodeId EntityIdentifier;
        SELECT  @DepAirportCodeId = AirportCodeID FROM  dbo.AirportCode WHERE   AirportCode = @DepAirportCode;
        SELECT  @ArrAirportCodeId = AirportCodeID FROM  dbo.AirportCode WHERE   AirportCode = @ArrAirportCode;

        -- Confirm non-existence before inserting
        IF NOT EXISTS
            (
                SELECT  1
                FROM    dbo.Routes R
                WHERE
                    R.DepAirportCodeID     = @DepAirportCodeId
                  AND   R.ArrAirportCodeID = @ArrAirportCodeId
            )
            BEGIN
                INSERT INTO dbo.Routes
                    (
                        RouteID
                      , DepAirportCodeID
                      , ArrAirportCodeID
                      , ActiveFlag
                      , APISFlag
                      , APISCheckInActiveDate
                      , SITASendAddresses
                      , EMAILSendAddresses
                      , ArrAPISFlag
                      , DepAPISFlag
                      , ICTSFlag
                      , ICTSActiveDate
                      , StartDate
                      , EndDate
                      , MadeiraDiscountActivationDate
                      , MadeiraDiscountFlag
                      , ResidentSpanishDiscountIsAvailable
                      , LargeFamilySpanishDiscountIsAvailable
                      , IsPromotionActive
                      , Direction
                      , IsHolidays
                      , BagBandChargeCodeID
                      , LocalDepartureActiveDate
                      , Route
                    )
                VALUES
                    (
                        (
                            SELECT  ISNULL(MAX(RouteID), 0) FROM    dbo.Routes WITH ( UPDLOCK )
                        ) + 1
                      , (
                            SELECT      AirportCodeID FROM  dbo.AirportCode WHERE   AirportCode = @DepAirportCode
                        )
                      , (
                            SELECT  AirportCodeID FROM  dbo.AirportCode WHERE   AirportCode = @ArrAirportCode
                        )
                      , @ActiveFlag
                      , @APISFlag
                      , '6 Jul 2016'
                      , NULL
                      , NULL
                      , @ArrAPISFlag
                      , @DepAPISFlag
                      , @ICTSFlag
                      , @ICTSActiveDate
                      , '6 Jul 2016'
                      , '20 May 2017'
                      , NULL
                      , NULL
                      , 0
                      , 0
                      , 0
                      , 1
                      , 0
                      , 168
                      , '6 Jul 2016'
                      , @Route
                    );
            END;
        ELSE
            BEGIN
                UPDATE
                    dbo.Routes
                SET
                    ActiveFlag = @ActiveFlag
                  , APISFlag = @APISFlag
                  , APISCheckInActiveDate = '6 Jul 2016'
                  , SITASendAddresses = NULL
                  , EMAILSendAddresses = NULL
                  , ArrAPISFlag = @ArrAPISFlag
                  , DepAPISFlag = @DepAPISFlag
                  , ICTSFlag = @ICTSFlag
                  , ICTSActiveDate = @ICTSActiveDate
                  , StartDate = '6 Jul 2016'
                  , EndDate = '20 May 2017'
                  , MadeiraDiscountActivationDate = NULL
                  , MadeiraDiscountFlag = NULL
                  , ResidentSpanishDiscountIsAvailable = 0
                  , LargeFamilySpanishDiscountIsAvailable = 0
                  , IsPromotionActive = 0
                  , Direction = 1
                  , IsHolidays = 0
                  , BagBandChargeCodeID = 168
                  , LocalDepartureActiveDate = '6 Jul 2016'
                  , Route = @Route
                WHERE
                    DepAirportCodeID     = @DepAirportCodeId
                  AND   ArrAirportCodeID = @ArrAirportCodeId;
            END;
    END;

GO
BEGIN TRY
BEGIN TRANSACTION
PRINT N'Deleting existing EZ9 data...'
/*******************************************************************************
* Delete Existing EZ9 DATA
* NB. Not deleting any "sectors" from the Route table. Even if we could identify
* if sectors were added in connection with the "EZ9" Golden Data they may have 
* subsequently been used or edited outside of EZ9.
********************************************************************************/

USE [ejFlight]

PRINT N'Determining FlightIdsToDelete...'
SELECT FlightID 
INTO #FlightIdsToDelete 
FROM dbo.Flight 
WHERE CarrierCode = 'EZ' AND FlightNumber LIKE '9%';

-- The relationship between the FlightFares and FareClassCodes is not 1:1 (it may be 1:1 for EZ9 created 
-- entries but it doesn't seem correct to simply assume that it is) so we only delete FareClassCodes that
-- are ONLY referenced by FlightFares that will be deleted....

PRINT N'Determining FareClassCodeIDsInUseOutsideEZ9...'
SELECT FF.FareClassCodeID
INTO #FareClassCodeIDsInUseOutsideEZ9
FROM FareClassCode FCC 
	INNER JOIN FlightFare FF ON 
		FF.FareClassCodeID = FF.FareClassCodeID
	WHERE FF.FlightID NOT IN 
		(SELECT FlightID FROM #FlightIdsToDelete)
GROUP BY FF.FareClassCodeID

PRINT N'Determining FareClassCodeIDsToDelete...'
SELECT FF.FareClassCodeID
INTO #FareClassCodeIDsToDelete
FROM FareClassCode FCC 
	INNER JOIN FlightFare FF ON 
		FF.FareClassCodeID = FCC.FareClassCodeID
	INNER JOIN #FlightIdsToDelete FTD ON
		FTD.FlightID = FF.FlightID
	WHERE FCC.FareClassCodeID NOT IN 
		(SELECT FareClassCodeID FROM #FareClassCodeIDsInUseOutsideEZ9)


PRINT N'Deleting FareClassPriceTranslation entries...'
DELETE FCPT 
FROM FareClassPriceTranslation FCPT 
INNER JOIN #FareClassCodeIDsToDelete FCCTD
	ON FCCTD.FareClassCodeID = FCPT.FareClassCodeID

PRINT N'Deleting FlightFare entries...'
DELETE FF
FROM FlightFare FF
INNER JOIN #FlightIdsToDelete FTD
	ON FTD.FlightID = FF.FlightID

PRINT N'Deleting FareClassCode entries...'
DELETE FCC
FROM FareClassCode FCC
INNER JOIN #FareClassCodeIDsToDelete FCCTD
	ON FCCTD.FareClassCodeID = FCCTD.FareClassCodeID

PRINT N'Deleting FlightCap entries...'
DELETE FC
FROM FlightCap FC
INNER JOIN #FlightIdsToDelete FTD
	ON FTD.FlightID = FC.FlightID

PRINT N'Deleting Flight entries...'
DELETE F
FROM Flight F
INNER JOIN #FlightIdsToDelete FTD
	ON FTD.FlightID = F.FlightID




PRINT N'Adding new EZ9 data...'
EXEC dbo.CreateSector 'LTN', 'ALC', 'Y', 'LTNALC'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/03/2016 07:00:00', '11/03/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161103LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161103LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161103LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161103LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161103LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161103LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161103LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161103LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/04/2016 07:00:00', '11/04/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161104LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161104LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161104LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161104LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161104LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161104LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161104LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161104LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/07/2016 07:00:00', '11/07/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161107LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161107LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161107LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161107LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161107LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161107LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161107LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161107LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/08/2016 07:00:00', '11/08/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161108LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161108LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161108LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161108LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161108LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161108LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161108LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161108LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/10/2016 07:00:00', '11/10/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161110LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161110LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161110LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161110LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161110LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161110LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161110LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161110LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/11/2016 07:00:00', '11/11/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161111LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161111LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161111LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161111LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161111LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161111LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161111LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161111LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/14/2016 07:00:00', '11/14/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161114LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161114LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161114LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161114LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161114LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161114LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161114LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161114LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/15/2016 07:00:00', '11/15/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161115LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161115LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161115LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161115LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161115LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161115LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161115LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161115LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/17/2016 07:00:00', '11/17/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161117LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161117LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161117LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161117LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161117LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161117LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161117LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161117LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/18/2016 07:00:00', '11/18/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161118LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161118LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161118LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161118LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161118LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161118LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161118LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161118LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/21/2016 07:00:00', '11/21/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161121LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161121LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161121LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161121LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161121LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161121LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161121LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161121LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/22/2016 07:00:00', '11/22/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161122LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161122LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161122LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161122LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161122LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161122LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161122LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161122LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/24/2016 07:00:00', '11/24/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161124LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161124LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161124LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161124LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161124LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161124LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161124LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161124LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/25/2016 07:00:00', '11/25/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161125LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161125LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161125LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161125LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161125LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161125LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161125LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161125LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/28/2016 07:00:00', '11/28/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161128LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161128LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161128LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161128LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161128LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161128LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161128LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161128LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/29/2016 07:00:00', '11/29/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161129LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161129LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161129LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161129LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161129LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161129LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161129LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161129LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/01/2016 07:00:00', '12/01/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161201LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161201LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161201LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161201LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161201LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161201LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161201LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161201LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/02/2016 07:00:00', '12/02/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161202LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161202LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161202LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161202LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161202LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161202LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161202LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161202LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/05/2016 07:00:00', '12/05/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161205LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161205LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161205LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161205LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161205LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161205LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161205LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161205LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/06/2016 07:00:00', '12/06/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161206LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161206LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161206LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161206LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161206LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161206LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161206LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161206LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/08/2016 07:00:00', '12/08/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161208LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161208LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161208LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161208LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161208LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161208LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161208LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161208LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/09/2016 07:00:00', '12/09/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161209LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161209LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161209LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161209LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161209LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161209LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161209LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161209LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/12/2016 07:00:00', '12/12/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161212LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161212LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161212LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161212LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161212LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161212LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161212LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161212LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/13/2016 07:00:00', '12/13/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161213LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161213LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161213LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161213LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161213LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161213LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161213LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161213LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/15/2016 07:00:00', '12/15/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161215LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161215LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161215LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161215LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161215LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161215LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161215LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161215LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/16/2016 07:00:00', '12/16/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161216LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161216LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161216LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161216LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161216LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161216LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161216LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161216LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/19/2016 07:00:00', '12/19/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161219LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161219LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161219LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161219LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161219LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161219LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161219LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161219LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/20/2016 07:00:00', '12/20/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161220LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161220LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161220LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161220LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161220LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161220LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161220LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161220LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/22/2016 07:00:00', '12/22/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161222LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161222LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161222LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161222LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161222LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161222LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161222LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161222LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/23/2016 07:00:00', '12/23/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161223LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161223LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161223LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161223LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161223LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161223LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161223LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161223LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/26/2016 07:00:00', '12/26/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161226LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161226LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161226LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161226LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161226LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161226LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161226LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161226LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/27/2016 07:00:00', '12/27/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161227LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161227LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161227LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161227LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161227LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161227LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161227LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161227LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/29/2016 07:00:00', '12/29/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161229LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161229LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161229LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161229LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161229LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161229LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161229LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161229LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/30/2016 07:00:00', '12/30/2016 08:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161230LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161230LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161230LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161230LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161230LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161230LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161230LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161230LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/02/2017 07:00:00', '01/02/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170102LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170102LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170102LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170102LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170102LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170102LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170102LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170102LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/03/2017 07:00:00', '01/03/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170103LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170103LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170103LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170103LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170103LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170103LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170103LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170103LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/05/2017 07:00:00', '01/05/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170105LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170105LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170105LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170105LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170105LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170105LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170105LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170105LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/06/2017 07:00:00', '01/06/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170106LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170106LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170106LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170106LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170106LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170106LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170106LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170106LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/09/2017 07:00:00', '01/09/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170109LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170109LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170109LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170109LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170109LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170109LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170109LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170109LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/10/2017 07:00:00', '01/10/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170110LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170110LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170110LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170110LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170110LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170110LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170110LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170110LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/12/2017 07:00:00', '01/12/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170112LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170112LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170112LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170112LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170112LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170112LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170112LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170112LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/13/2017 07:00:00', '01/13/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170113LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170113LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170113LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170113LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170113LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170113LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170113LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170113LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/16/2017 07:00:00', '01/16/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170116LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170116LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170116LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170116LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170116LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170116LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170116LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170116LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/17/2017 07:00:00', '01/17/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170117LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170117LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170117LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170117LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170117LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170117LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170117LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170117LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/19/2017 07:00:00', '01/19/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170119LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170119LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170119LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170119LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170119LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170119LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170119LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170119LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/20/2017 07:00:00', '01/20/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170120LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170120LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170120LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170120LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170120LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170120LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170120LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170120LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/23/2017 07:00:00', '01/23/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170123LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170123LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170123LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170123LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170123LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170123LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170123LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170123LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/24/2017 07:00:00', '01/24/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170124LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170124LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170124LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170124LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170124LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170124LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170124LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170124LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/26/2017 07:00:00', '01/26/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170126LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170126LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170126LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170126LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170126LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170126LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170126LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170126LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/27/2017 07:00:00', '01/27/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170127LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170127LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170127LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170127LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170127LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170127LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170127LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170127LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/30/2017 07:00:00', '01/30/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170130LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170130LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170130LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170130LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170130LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170130LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170130LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170130LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/31/2017 07:00:00', '01/31/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170131LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170131LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170131LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170131LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170131LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170131LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170131LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170131LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/02/2017 07:00:00', '02/02/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170202LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170202LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170202LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170202LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170202LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170202LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170202LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170202LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/03/2017 07:00:00', '02/03/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170203LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170203LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170203LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170203LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170203LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170203LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170203LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170203LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/06/2017 07:00:00', '02/06/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170206LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170206LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170206LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170206LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170206LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170206LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170206LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170206LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/07/2017 07:00:00', '02/07/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170207LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170207LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170207LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170207LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170207LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170207LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170207LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170207LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/09/2017 07:00:00', '02/09/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170209LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170209LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170209LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170209LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170209LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170209LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170209LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170209LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/10/2017 07:00:00', '02/10/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170210LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170210LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170210LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170210LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170210LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170210LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170210LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170210LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/13/2017 07:00:00', '02/13/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170213LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170213LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170213LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170213LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170213LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170213LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170213LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170213LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/14/2017 07:00:00', '02/14/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170214LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170214LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170214LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170214LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170214LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170214LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170214LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170214LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/16/2017 07:00:00', '02/16/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170216LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170216LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170216LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170216LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170216LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170216LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170216LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170216LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/17/2017 07:00:00', '02/17/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170217LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170217LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170217LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170217LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170217LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170217LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170217LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170217LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/20/2017 07:00:00', '02/20/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170220LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170220LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170220LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170220LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170220LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170220LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170220LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170220LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/21/2017 07:00:00', '02/21/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170221LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170221LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170221LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170221LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170221LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170221LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170221LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170221LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/23/2017 07:00:00', '02/23/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170223LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170223LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170223LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170223LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170223LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170223LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170223LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170223LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/24/2017 07:00:00', '02/24/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170224LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170224LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170224LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170224LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170224LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170224LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170224LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170224LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/27/2017 07:00:00', '02/27/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170227LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170227LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170227LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170227LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170227LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170227LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170227LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170227LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/28/2017 07:00:00', '02/28/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170228LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170228LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170228LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170228LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170228LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170228LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170228LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170228LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/02/2017 07:00:00', '03/02/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170302LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170302LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170302LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170302LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170302LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170302LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170302LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170302LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/03/2017 07:00:00', '03/03/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170303LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170303LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170303LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170303LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170303LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170303LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170303LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170303LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/06/2017 07:00:00', '03/06/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170306LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170306LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170306LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170306LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170306LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170306LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170306LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170306LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/07/2017 07:00:00', '03/07/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170307LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170307LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170307LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170307LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170307LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170307LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170307LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170307LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/09/2017 07:00:00', '03/09/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170309LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170309LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170309LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170309LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170309LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170309LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170309LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170309LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/10/2017 07:00:00', '03/10/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170310LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170310LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170310LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170310LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170310LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170310LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170310LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170310LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/13/2017 07:00:00', '03/13/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170313LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170313LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170313LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170313LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170313LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170313LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170313LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170313LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/14/2017 07:00:00', '03/14/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170314LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170314LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170314LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170314LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170314LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170314LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170314LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170314LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/16/2017 07:00:00', '03/16/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170316LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170316LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170316LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170316LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170316LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170316LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170316LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170316LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/17/2017 07:00:00', '03/17/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170317LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170317LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170317LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170317LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170317LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170317LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170317LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170317LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/20/2017 07:00:00', '03/20/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170320LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170320LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170320LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170320LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170320LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170320LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170320LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170320LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/21/2017 07:00:00', '03/21/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170321LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170321LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170321LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170321LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170321LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170321LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170321LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170321LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/23/2017 07:00:00', '03/23/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170323LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170323LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170323LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170323LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170323LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170323LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170323LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170323LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/24/2017 07:00:00', '03/24/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170324LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170324LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170324LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170324LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170324LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170324LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170324LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170324LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/27/2017 07:00:00', '03/27/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170327LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170327LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170327LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170327LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170327LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170327LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170327LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170327LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/28/2017 07:00:00', '03/28/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170328LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170328LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170328LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170328LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170328LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170328LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170328LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170328LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/30/2017 07:00:00', '03/30/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170330LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170330LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170330LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170330LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170330LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170330LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170330LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170330LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/31/2017 07:00:00', '03/31/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170331LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170331LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170331LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170331LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170331LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170331LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170331LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170331LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/03/2017 07:00:00', '04/03/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170403LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170403LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170403LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170403LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170403LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170403LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170403LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170403LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/04/2017 07:00:00', '04/04/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170404LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170404LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170404LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170404LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170404LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170404LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170404LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170404LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/06/2017 07:00:00', '04/06/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170406LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170406LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170406LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170406LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170406LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170406LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170406LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170406LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/07/2017 07:00:00', '04/07/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170407LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170407LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170407LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170407LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170407LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170407LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170407LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170407LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/10/2017 07:00:00', '04/10/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170410LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170410LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170410LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170410LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170410LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170410LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170410LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170410LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/11/2017 07:00:00', '04/11/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170411LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170411LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170411LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170411LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170411LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170411LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170411LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170411LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/13/2017 07:00:00', '04/13/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170413LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170413LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170413LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170413LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170413LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170413LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170413LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170413LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/14/2017 07:00:00', '04/14/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170414LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170414LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170414LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170414LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170414LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170414LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170414LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170414LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/17/2017 07:00:00', '04/17/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170417LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170417LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170417LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170417LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170417LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170417LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170417LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170417LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/18/2017 07:00:00', '04/18/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170418LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170418LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170418LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170418LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170418LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170418LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170418LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170418LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/20/2017 07:00:00', '04/20/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170420LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170420LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170420LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170420LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170420LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170420LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170420LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170420LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/21/2017 07:00:00', '04/21/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170421LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170421LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170421LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170421LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170421LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170421LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170421LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170421LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/24/2017 07:00:00', '04/24/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170424LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170424LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170424LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170424LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170424LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170424LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170424LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170424LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/25/2017 07:00:00', '04/25/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170425LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170425LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170425LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170425LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170425LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170425LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170425LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170425LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/27/2017 07:00:00', '04/27/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170427LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170427LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170427LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170427LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170427LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170427LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170427LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170427LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/28/2017 07:00:00', '04/28/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170428LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170428LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170428LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170428LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170428LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170428LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170428LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170428LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '05/01/2017 07:00:00', '05/01/2017 08:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170501LTNALC9101', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170501LTNALC9101', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170501LTNALC9101', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170501LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170501LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170501LTNALC9101', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170501LTNALC9101', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170501LTNALC9101', 'Internet', 0, 39, 0
EXEC dbo.CreateSector 'LTN', 'ALC', 'Y', 'LTNALC'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/02/2016 07:00:00', '11/02/2016 08:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161102LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161102LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161102LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161102LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161102LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161102LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/09/2016 07:00:00', '11/09/2016 08:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161109LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161109LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161109LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161109LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161109LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161109LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/16/2016 07:00:00', '11/16/2016 08:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161116LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161116LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161116LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161116LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161116LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161116LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/23/2016 07:00:00', '11/23/2016 08:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161123LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161123LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161123LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161123LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161123LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161123LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/30/2016 07:00:00', '11/30/2016 08:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161130LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161130LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161130LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161130LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161130LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161130LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/07/2016 07:00:00', '12/07/2016 08:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161207LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161207LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161207LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161207LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161207LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161207LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/14/2016 07:00:00', '12/14/2016 08:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161214LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161214LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161214LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161214LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161214LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161214LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/21/2016 07:00:00', '12/21/2016 08:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161221LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161221LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161221LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161221LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161221LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161221LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/28/2016 07:00:00', '12/28/2016 08:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161228LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161228LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161228LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161228LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161228LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161228LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/04/2017 07:00:00', '01/04/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170104LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170104LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170104LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170104LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170104LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170104LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/11/2017 07:00:00', '01/11/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170111LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170111LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170111LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170111LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170111LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170111LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/18/2017 07:00:00', '01/18/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170118LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170118LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170118LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170118LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170118LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170118LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/25/2017 07:00:00', '01/25/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170125LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170125LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170125LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170125LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170125LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170125LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/01/2017 07:00:00', '02/01/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170201LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170201LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170201LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170201LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170201LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170201LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/08/2017 07:00:00', '02/08/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170208LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170208LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170208LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170208LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170208LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170208LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/15/2017 07:00:00', '02/15/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170215LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170215LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170215LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170215LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170215LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170215LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/22/2017 07:00:00', '02/22/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170222LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170222LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170222LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170222LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170222LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170222LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/01/2017 07:00:00', '03/01/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170301LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170301LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170301LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170301LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170301LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170301LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/08/2017 07:00:00', '03/08/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170308LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170308LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170308LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170308LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170308LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170308LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/15/2017 07:00:00', '03/15/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170315LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170315LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170315LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170315LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170315LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170315LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/22/2017 07:00:00', '03/22/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170322LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170322LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170322LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170322LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170322LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170322LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/29/2017 07:00:00', '03/29/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170329LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170329LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170329LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170329LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170329LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170329LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/05/2017 07:00:00', '04/05/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170405LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170405LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170405LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170405LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170405LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170405LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/12/2017 07:00:00', '04/12/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170412LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170412LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170412LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170412LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170412LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170412LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/19/2017 07:00:00', '04/19/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170419LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170419LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170419LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170419LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170419LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170419LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/26/2017 07:00:00', '04/26/2017 08:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170426LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170426LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170426LTNALC9101', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170426LTNALC9101', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170426LTNALC9101', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170426LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateSector 'LTN', 'ALC', 'Y', 'LTNALC'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/05/2016 07:00:00', '11/05/2016 08:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161105LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161105LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161105LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161105LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161105LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161105LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161105LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161105LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/12/2016 07:00:00', '11/12/2016 08:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161112LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161112LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161112LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161112LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161112LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161112LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161112LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161112LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/19/2016 07:00:00', '11/19/2016 08:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161119LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161119LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161119LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161119LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161119LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161119LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161119LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161119LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '11/26/2016 07:00:00', '11/26/2016 08:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161126LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161126LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161126LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161126LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161126LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161126LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161126LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161126LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/03/2016 07:00:00', '12/03/2016 08:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161203LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161203LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161203LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161203LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161203LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161203LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161203LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161203LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/10/2016 07:00:00', '12/10/2016 08:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161210LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161210LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161210LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161210LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161210LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161210LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161210LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161210LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/17/2016 07:00:00', '12/17/2016 08:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161217LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161217LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161217LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161217LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161217LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161217LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161217LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161217LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/24/2016 07:00:00', '12/24/2016 08:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161224LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161224LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161224LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161224LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161224LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161224LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161224LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161224LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '12/31/2016 07:00:00', '12/31/2016 08:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161231LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161231LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161231LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161231LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161231LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161231LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161231LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161231LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/07/2017 07:00:00', '01/07/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170107LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170107LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170107LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170107LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170107LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170107LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170107LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170107LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/14/2017 07:00:00', '01/14/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170114LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170114LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170114LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170114LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170114LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170114LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170114LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170114LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/21/2017 07:00:00', '01/21/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170121LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170121LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170121LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170121LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170121LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170121LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170121LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170121LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '01/28/2017 07:00:00', '01/28/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170128LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170128LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170128LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170128LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170128LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170128LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170128LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170128LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/04/2017 07:00:00', '02/04/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170204LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170204LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170204LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170204LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170204LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170204LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170204LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170204LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/11/2017 07:00:00', '02/11/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170211LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170211LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170211LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170211LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170211LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170211LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170211LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170211LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/18/2017 07:00:00', '02/18/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170218LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170218LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170218LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170218LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170218LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170218LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170218LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170218LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '02/25/2017 07:00:00', '02/25/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170225LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170225LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170225LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170225LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170225LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170225LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170225LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170225LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/04/2017 07:00:00', '03/04/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170304LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170304LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170304LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170304LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170304LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170304LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170304LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170304LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/11/2017 07:00:00', '03/11/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170311LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170311LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170311LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170311LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170311LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170311LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170311LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170311LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/18/2017 07:00:00', '03/18/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170318LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170318LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170318LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170318LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170318LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170318LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170318LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170318LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '03/25/2017 07:00:00', '03/25/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170325LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170325LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170325LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170325LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170325LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170325LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170325LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170325LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/01/2017 07:00:00', '04/01/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170401LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170401LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170401LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170401LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170401LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170401LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170401LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170401LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/08/2017 07:00:00', '04/08/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170408LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170408LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170408LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170408LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170408LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170408LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170408LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170408LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/15/2017 07:00:00', '04/15/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170415LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170415LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170415LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170415LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170415LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170415LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170415LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170415LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/22/2017 07:00:00', '04/22/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170422LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170422LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170422LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170422LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170422LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170422LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170422LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170422LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9101      ', '04/29/2017 07:00:00', '04/29/2017 08:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170429LTNALC9101', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170429LTNALC9101', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170429LTNALC9101', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170429LTNALC9101', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170429LTNALC9101', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170429LTNALC9101', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170429LTNALC9101', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170429LTNALC9101', 'Internet', 60, 79, 0
EXEC dbo.CreateSector 'ALC', 'LTN', 'Y', 'ALCLTN'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/02/2016 09:15:00', '11/02/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161102ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161102ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161102ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161102ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161102ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161102ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161102ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161102ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/03/2016 09:15:00', '11/03/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161103ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161103ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161103ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161103ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161103ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161103ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161103ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161103ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/05/2016 09:15:00', '11/05/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161105ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161105ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161105ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161105ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161105ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161105ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161105ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161105ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/07/2016 09:15:00', '11/07/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161107ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161107ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161107ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161107ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161107ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161107ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161107ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161107ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/09/2016 09:15:00', '11/09/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161109ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161109ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161109ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161109ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161109ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161109ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161109ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161109ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/10/2016 09:15:00', '11/10/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161110ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161110ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161110ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161110ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161110ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161110ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161110ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161110ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/12/2016 09:15:00', '11/12/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161112ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161112ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161112ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161112ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161112ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161112ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161112ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161112ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/14/2016 09:15:00', '11/14/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161114ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161114ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161114ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161114ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161114ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161114ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161114ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161114ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/16/2016 09:15:00', '11/16/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161116ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161116ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161116ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161116ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161116ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161116ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161116ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161116ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/17/2016 09:15:00', '11/17/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161117ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161117ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161117ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161117ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161117ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161117ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161117ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161117ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/19/2016 09:15:00', '11/19/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161119ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161119ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161119ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161119ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161119ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161119ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161119ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161119ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/21/2016 09:15:00', '11/21/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161121ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161121ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161121ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161121ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161121ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161121ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161121ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161121ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/23/2016 09:15:00', '11/23/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161123ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161123ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161123ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161123ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161123ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161123ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161123ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161123ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/24/2016 09:15:00', '11/24/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161124ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161124ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161124ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161124ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161124ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161124ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161124ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161124ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/26/2016 09:15:00', '11/26/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161126ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161126ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161126ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161126ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161126ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161126ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161126ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161126ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/28/2016 09:15:00', '11/28/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161128ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161128ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161128ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161128ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161128ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161128ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161128ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161128ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/30/2016 09:15:00', '11/30/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161130ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161130ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161130ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161130ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161130ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161130ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161130ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161130ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/01/2016 09:15:00', '12/01/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161201ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161201ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161201ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161201ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161201ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161201ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161201ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161201ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/03/2016 09:15:00', '12/03/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161203ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161203ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161203ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161203ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161203ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161203ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161203ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161203ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/05/2016 09:15:00', '12/05/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161205ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161205ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161205ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161205ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161205ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161205ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161205ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161205ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/07/2016 09:15:00', '12/07/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161207ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161207ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161207ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161207ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161207ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161207ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161207ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161207ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/08/2016 09:15:00', '12/08/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161208ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161208ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161208ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161208ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161208ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161208ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161208ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161208ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/10/2016 09:15:00', '12/10/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161210ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161210ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161210ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161210ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161210ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161210ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161210ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161210ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/12/2016 09:15:00', '12/12/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161212ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161212ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161212ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161212ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161212ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161212ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161212ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161212ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/14/2016 09:15:00', '12/14/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161214ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161214ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161214ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161214ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161214ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161214ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161214ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161214ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/15/2016 09:15:00', '12/15/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161215ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161215ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161215ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161215ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161215ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161215ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161215ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161215ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/17/2016 09:15:00', '12/17/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161217ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161217ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161217ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161217ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161217ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161217ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161217ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161217ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/19/2016 09:15:00', '12/19/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161219ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161219ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161219ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161219ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161219ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161219ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161219ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161219ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/21/2016 09:15:00', '12/21/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161221ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161221ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161221ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161221ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161221ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161221ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161221ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161221ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/22/2016 09:15:00', '12/22/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161222ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161222ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161222ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161222ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161222ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161222ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161222ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161222ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/24/2016 09:15:00', '12/24/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161224ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161224ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161224ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161224ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161224ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161224ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161224ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161224ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/26/2016 09:15:00', '12/26/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161226ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161226ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161226ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161226ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161226ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161226ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161226ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161226ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/28/2016 09:15:00', '12/28/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161228ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161228ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161228ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161228ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161228ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161228ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161228ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161228ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/29/2016 09:15:00', '12/29/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161229ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161229ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161229ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161229ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161229ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161229ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161229ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161229ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/31/2016 09:15:00', '12/31/2016 10:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161231ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161231ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161231ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161231ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161231ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161231ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161231ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161231ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/02/2017 09:15:00', '01/02/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170102ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170102ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170102ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170102ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170102ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170102ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170102ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170102ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/04/2017 09:15:00', '01/04/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170104ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170104ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170104ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170104ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170104ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170104ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170104ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170104ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/05/2017 09:15:00', '01/05/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170105ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170105ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170105ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170105ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170105ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170105ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170105ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170105ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/07/2017 09:15:00', '01/07/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170107ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170107ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170107ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170107ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170107ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170107ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170107ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170107ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/09/2017 09:15:00', '01/09/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170109ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170109ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170109ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170109ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170109ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170109ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170109ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170109ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/11/2017 09:15:00', '01/11/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170111ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170111ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170111ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170111ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170111ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170111ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170111ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170111ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/12/2017 09:15:00', '01/12/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170112ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170112ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170112ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170112ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170112ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170112ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170112ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170112ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/14/2017 09:15:00', '01/14/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170114ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170114ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170114ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170114ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170114ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170114ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170114ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170114ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/16/2017 09:15:00', '01/16/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170116ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170116ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170116ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170116ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170116ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170116ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170116ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170116ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/18/2017 09:15:00', '01/18/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170118ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170118ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170118ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170118ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170118ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170118ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170118ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170118ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/19/2017 09:15:00', '01/19/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170119ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170119ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170119ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170119ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170119ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170119ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170119ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170119ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/21/2017 09:15:00', '01/21/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170121ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170121ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170121ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170121ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170121ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170121ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170121ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170121ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/23/2017 09:15:00', '01/23/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170123ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170123ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170123ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170123ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170123ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170123ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170123ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170123ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/25/2017 09:15:00', '01/25/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170125ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170125ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170125ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170125ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170125ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170125ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170125ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170125ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/26/2017 09:15:00', '01/26/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170126ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170126ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170126ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170126ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170126ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170126ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170126ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170126ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/28/2017 09:15:00', '01/28/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170128ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170128ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170128ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170128ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170128ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170128ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170128ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170128ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/30/2017 09:15:00', '01/30/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170130ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170130ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170130ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170130ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170130ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170130ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170130ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170130ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/01/2017 09:15:00', '02/01/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170201ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170201ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170201ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170201ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170201ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170201ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170201ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170201ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/02/2017 09:15:00', '02/02/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170202ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170202ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170202ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170202ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170202ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170202ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170202ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170202ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/04/2017 09:15:00', '02/04/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170204ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170204ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170204ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170204ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170204ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170204ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170204ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170204ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/06/2017 09:15:00', '02/06/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170206ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170206ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170206ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170206ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170206ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170206ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170206ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170206ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/08/2017 09:15:00', '02/08/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170208ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170208ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170208ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170208ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170208ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170208ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170208ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170208ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/09/2017 09:15:00', '02/09/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170209ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170209ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170209ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170209ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170209ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170209ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170209ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170209ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/11/2017 09:15:00', '02/11/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170211ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170211ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170211ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170211ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170211ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170211ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170211ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170211ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/13/2017 09:15:00', '02/13/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170213ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170213ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170213ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170213ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170213ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170213ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170213ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170213ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/15/2017 09:15:00', '02/15/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170215ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170215ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170215ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170215ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170215ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170215ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170215ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170215ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/16/2017 09:15:00', '02/16/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170216ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170216ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170216ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170216ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170216ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170216ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170216ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170216ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/18/2017 09:15:00', '02/18/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170218ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170218ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170218ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170218ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170218ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170218ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170218ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170218ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/20/2017 09:15:00', '02/20/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170220ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170220ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170220ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170220ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170220ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170220ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170220ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170220ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/22/2017 09:15:00', '02/22/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170222ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170222ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170222ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170222ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170222ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170222ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170222ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170222ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/23/2017 09:15:00', '02/23/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170223ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170223ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170223ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170223ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170223ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170223ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170223ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170223ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/25/2017 09:15:00', '02/25/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170225ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170225ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170225ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170225ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170225ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170225ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170225ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170225ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/27/2017 09:15:00', '02/27/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170227ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170227ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170227ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170227ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170227ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170227ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170227ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170227ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/01/2017 09:15:00', '03/01/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170301ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170301ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170301ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170301ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170301ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170301ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170301ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170301ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/02/2017 09:15:00', '03/02/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170302ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170302ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170302ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170302ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170302ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170302ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170302ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170302ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/04/2017 09:15:00', '03/04/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170304ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170304ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170304ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170304ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170304ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170304ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170304ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170304ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/06/2017 09:15:00', '03/06/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170306ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170306ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170306ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170306ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170306ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170306ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170306ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170306ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/08/2017 09:15:00', '03/08/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170308ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170308ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170308ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170308ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170308ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170308ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170308ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170308ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/09/2017 09:15:00', '03/09/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170309ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170309ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170309ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170309ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170309ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170309ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170309ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170309ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/11/2017 09:15:00', '03/11/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170311ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170311ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170311ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170311ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170311ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170311ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170311ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170311ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/13/2017 09:15:00', '03/13/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170313ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170313ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170313ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170313ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170313ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170313ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170313ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170313ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/15/2017 09:15:00', '03/15/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170315ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170315ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170315ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170315ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170315ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170315ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170315ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170315ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/16/2017 09:15:00', '03/16/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170316ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170316ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170316ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170316ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170316ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170316ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170316ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170316ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/18/2017 09:15:00', '03/18/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170318ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170318ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170318ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170318ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170318ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170318ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170318ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170318ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/20/2017 09:15:00', '03/20/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170320ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170320ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170320ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170320ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170320ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170320ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170320ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170320ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/22/2017 09:15:00', '03/22/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170322ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170322ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170322ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170322ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170322ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170322ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170322ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170322ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/23/2017 09:15:00', '03/23/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170323ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170323ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170323ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170323ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170323ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170323ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170323ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170323ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/25/2017 09:15:00', '03/25/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170325ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170325ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170325ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170325ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170325ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170325ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170325ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170325ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/27/2017 09:15:00', '03/27/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170327ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170327ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170327ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170327ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170327ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170327ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170327ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170327ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/29/2017 09:15:00', '03/29/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170329ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170329ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170329ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170329ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170329ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170329ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170329ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170329ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/30/2017 09:15:00', '03/30/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170330ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170330ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170330ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170330ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170330ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170330ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170330ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170330ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/01/2017 09:15:00', '04/01/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170401ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170401ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170401ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170401ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170401ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170401ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170401ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170401ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/03/2017 09:15:00', '04/03/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170403ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170403ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170403ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170403ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170403ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170403ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170403ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170403ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/05/2017 09:15:00', '04/05/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170405ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170405ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170405ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170405ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170405ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170405ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170405ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170405ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/06/2017 09:15:00', '04/06/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170406ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170406ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170406ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170406ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170406ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170406ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170406ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170406ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/08/2017 09:15:00', '04/08/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170408ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170408ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170408ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170408ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170408ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170408ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170408ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170408ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/10/2017 09:15:00', '04/10/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170410ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170410ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170410ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170410ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170410ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170410ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170410ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170410ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/12/2017 09:15:00', '04/12/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170412ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170412ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170412ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170412ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170412ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170412ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170412ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170412ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/13/2017 09:15:00', '04/13/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170413ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170413ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170413ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170413ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170413ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170413ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170413ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170413ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/15/2017 09:15:00', '04/15/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170415ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170415ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170415ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170415ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170415ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170415ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170415ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170415ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/17/2017 09:15:00', '04/17/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170417ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170417ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170417ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170417ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170417ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170417ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170417ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170417ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/19/2017 09:15:00', '04/19/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170419ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170419ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170419ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170419ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170419ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170419ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170419ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170419ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/20/2017 09:15:00', '04/20/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170420ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170420ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170420ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170420ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170420ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170420ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170420ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170420ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/22/2017 09:15:00', '04/22/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170422ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170422ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170422ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170422ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170422ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170422ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170422ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170422ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/24/2017 09:15:00', '04/24/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170424ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170424ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170424ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170424ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170424ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170424ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170424ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170424ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/26/2017 09:15:00', '04/26/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170426ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170426ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170426ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170426ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170426ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170426ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170426ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170426ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/27/2017 09:15:00', '04/27/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170427ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170427ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170427ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170427ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170427ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170427ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170427ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170427ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/29/2017 09:15:00', '04/29/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170429ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170429ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170429ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170429ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170429ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170429ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170429ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170429ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '05/01/2017 09:15:00', '05/01/2017 10:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170501ALCLTN9102', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170501ALCLTN9102', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170501ALCLTN9102', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170501ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170501ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170501ALCLTN9102', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170501ALCLTN9102', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170501ALCLTN9102', 'Internet', 0, 39, 0
EXEC dbo.CreateSector 'ALC', 'LTN', 'Y', 'ALCLTN'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/08/2016 09:15:00', '11/08/2016 10:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161108ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161108ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161108ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161108ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161108ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161108ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/15/2016 09:15:00', '11/15/2016 10:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161115ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161115ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161115ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161115ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161115ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161115ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/22/2016 09:15:00', '11/22/2016 10:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161122ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161122ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161122ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161122ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161122ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161122ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/29/2016 09:15:00', '11/29/2016 10:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161129ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161129ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161129ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161129ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161129ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161129ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/06/2016 09:15:00', '12/06/2016 10:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161206ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161206ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161206ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161206ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161206ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161206ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/13/2016 09:15:00', '12/13/2016 10:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161213ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161213ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161213ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161213ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161213ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161213ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/20/2016 09:15:00', '12/20/2016 10:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161220ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161220ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161220ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161220ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161220ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161220ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/27/2016 09:15:00', '12/27/2016 10:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161227ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161227ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161227ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161227ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161227ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161227ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/03/2017 09:15:00', '01/03/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170103ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170103ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170103ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170103ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170103ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170103ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/10/2017 09:15:00', '01/10/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170110ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170110ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170110ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170110ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170110ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170110ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/17/2017 09:15:00', '01/17/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170117ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170117ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170117ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170117ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170117ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170117ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/24/2017 09:15:00', '01/24/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170124ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170124ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170124ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170124ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170124ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170124ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/31/2017 09:15:00', '01/31/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170131ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170131ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170131ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170131ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170131ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170131ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/07/2017 09:15:00', '02/07/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170207ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170207ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170207ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170207ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170207ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170207ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/14/2017 09:15:00', '02/14/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170214ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170214ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170214ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170214ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170214ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170214ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/21/2017 09:15:00', '02/21/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170221ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170221ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170221ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170221ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170221ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170221ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/28/2017 09:15:00', '02/28/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170228ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170228ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170228ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170228ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170228ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170228ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/07/2017 09:15:00', '03/07/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170307ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170307ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170307ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170307ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170307ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170307ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/14/2017 09:15:00', '03/14/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170314ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170314ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170314ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170314ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170314ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170314ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/21/2017 09:15:00', '03/21/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170321ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170321ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170321ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170321ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170321ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170321ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/28/2017 09:15:00', '03/28/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170328ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170328ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170328ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170328ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170328ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170328ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/04/2017 09:15:00', '04/04/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170404ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170404ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170404ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170404ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170404ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170404ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/11/2017 09:15:00', '04/11/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170411ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170411ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170411ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170411ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170411ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170411ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/18/2017 09:15:00', '04/18/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170418ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170418ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170418ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170418ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170418ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170418ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/25/2017 09:15:00', '04/25/2017 10:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170425ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170425ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170425ALCLTN9102', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170425ALCLTN9102', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170425ALCLTN9102', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170425ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateSector 'ALC', 'LTN', 'Y', 'ALCLTN'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/04/2016 09:15:00', '11/04/2016 10:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161104ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161104ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161104ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161104ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161104ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161104ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161104ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161104ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/11/2016 09:15:00', '11/11/2016 10:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161111ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161111ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161111ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161111ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161111ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161111ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161111ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161111ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/18/2016 09:15:00', '11/18/2016 10:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161118ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161118ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161118ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161118ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161118ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161118ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161118ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161118ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '11/25/2016 09:15:00', '11/25/2016 10:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161125ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161125ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161125ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161125ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161125ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161125ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161125ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161125ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/02/2016 09:15:00', '12/02/2016 10:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161202ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161202ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161202ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161202ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161202ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161202ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161202ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161202ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/09/2016 09:15:00', '12/09/2016 10:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161209ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161209ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161209ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161209ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161209ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161209ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161209ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161209ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/16/2016 09:15:00', '12/16/2016 10:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161216ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161216ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161216ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161216ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161216ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161216ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161216ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161216ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/23/2016 09:15:00', '12/23/2016 10:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161223ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161223ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161223ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161223ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161223ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161223ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161223ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161223ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '12/30/2016 09:15:00', '12/30/2016 10:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161230ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161230ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161230ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161230ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161230ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161230ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161230ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161230ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/06/2017 09:15:00', '01/06/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170106ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170106ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170106ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170106ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170106ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170106ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170106ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170106ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/13/2017 09:15:00', '01/13/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170113ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170113ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170113ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170113ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170113ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170113ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170113ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170113ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/20/2017 09:15:00', '01/20/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170120ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170120ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170120ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170120ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170120ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170120ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170120ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170120ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '01/27/2017 09:15:00', '01/27/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170127ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170127ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170127ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170127ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170127ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170127ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170127ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170127ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/03/2017 09:15:00', '02/03/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170203ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170203ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170203ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170203ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170203ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170203ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170203ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170203ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/10/2017 09:15:00', '02/10/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170210ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170210ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170210ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170210ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170210ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170210ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170210ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170210ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/17/2017 09:15:00', '02/17/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170217ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170217ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170217ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170217ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170217ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170217ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170217ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170217ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '02/24/2017 09:15:00', '02/24/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170224ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170224ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170224ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170224ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170224ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170224ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170224ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170224ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/03/2017 09:15:00', '03/03/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170303ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170303ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170303ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170303ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170303ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170303ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170303ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170303ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/10/2017 09:15:00', '03/10/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170310ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170310ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170310ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170310ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170310ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170310ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170310ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170310ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/17/2017 09:15:00', '03/17/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170317ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170317ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170317ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170317ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170317ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170317ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170317ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170317ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/24/2017 09:15:00', '03/24/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170324ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170324ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170324ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170324ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170324ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170324ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170324ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170324ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '03/31/2017 09:15:00', '03/31/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170331ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170331ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170331ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170331ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170331ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170331ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170331ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170331ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/07/2017 09:15:00', '04/07/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170407ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170407ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170407ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170407ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170407ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170407ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170407ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170407ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/14/2017 09:15:00', '04/14/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170414ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170414ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170414ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170414ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170414ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170414ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170414ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170414ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/21/2017 09:15:00', '04/21/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170421ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170421ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170421ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170421ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170421ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170421ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170421ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170421ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9102      ', '04/28/2017 09:15:00', '04/28/2017 10:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170428ALCLTN9102', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170428ALCLTN9102', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170428ALCLTN9102', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170428ALCLTN9102', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170428ALCLTN9102', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170428ALCLTN9102', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170428ALCLTN9102', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170428ALCLTN9102', 'Internet', 60, 79, 0
EXEC dbo.CreateSector 'LTN', 'ALC', 'Y', 'LTNALC'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/02/2016 11:30:00', '11/02/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161102LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161102LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161102LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161102LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161102LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161102LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161102LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161102LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/04/2016 11:30:00', '11/04/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161104LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161104LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161104LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161104LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161104LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161104LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161104LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161104LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/05/2016 11:30:00', '11/05/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161105LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161105LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161105LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161105LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161105LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161105LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161105LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161105LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/08/2016 11:30:00', '11/08/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161108LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161108LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161108LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161108LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161108LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161108LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161108LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161108LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/09/2016 11:30:00', '11/09/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161109LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161109LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161109LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161109LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161109LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161109LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161109LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161109LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/11/2016 11:30:00', '11/11/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161111LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161111LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161111LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161111LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161111LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161111LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161111LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161111LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/12/2016 11:30:00', '11/12/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161112LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161112LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161112LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161112LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161112LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161112LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161112LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161112LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/15/2016 11:30:00', '11/15/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161115LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161115LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161115LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161115LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161115LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161115LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161115LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161115LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/16/2016 11:30:00', '11/16/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161116LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161116LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161116LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161116LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161116LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161116LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161116LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161116LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/18/2016 11:30:00', '11/18/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161118LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161118LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161118LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161118LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161118LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161118LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161118LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161118LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/19/2016 11:30:00', '11/19/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161119LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161119LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161119LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161119LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161119LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161119LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161119LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161119LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/22/2016 11:30:00', '11/22/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161122LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161122LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161122LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161122LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161122LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161122LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161122LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161122LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/23/2016 11:30:00', '11/23/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161123LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161123LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161123LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161123LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161123LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161123LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161123LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161123LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/25/2016 11:30:00', '11/25/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161125LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161125LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161125LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161125LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161125LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161125LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161125LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161125LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/26/2016 11:30:00', '11/26/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161126LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161126LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161126LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161126LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161126LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161126LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161126LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161126LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/29/2016 11:30:00', '11/29/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161129LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161129LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161129LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161129LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161129LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161129LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161129LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161129LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/30/2016 11:30:00', '11/30/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161130LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161130LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161130LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161130LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161130LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161130LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161130LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161130LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/02/2016 11:30:00', '12/02/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161202LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161202LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161202LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161202LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161202LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161202LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161202LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161202LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/03/2016 11:30:00', '12/03/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161203LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161203LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161203LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161203LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161203LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161203LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161203LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161203LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/06/2016 11:30:00', '12/06/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161206LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161206LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161206LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161206LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161206LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161206LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161206LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161206LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/07/2016 11:30:00', '12/07/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161207LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161207LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161207LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161207LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161207LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161207LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161207LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161207LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/09/2016 11:30:00', '12/09/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161209LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161209LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161209LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161209LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161209LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161209LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161209LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161209LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/10/2016 11:30:00', '12/10/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161210LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161210LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161210LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161210LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161210LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161210LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161210LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161210LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/13/2016 11:30:00', '12/13/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161213LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161213LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161213LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161213LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161213LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161213LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161213LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161213LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/14/2016 11:30:00', '12/14/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161214LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161214LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161214LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161214LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161214LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161214LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161214LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161214LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/16/2016 11:30:00', '12/16/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161216LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161216LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161216LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161216LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161216LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161216LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161216LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161216LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/17/2016 11:30:00', '12/17/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161217LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161217LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161217LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161217LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161217LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161217LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161217LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161217LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/20/2016 11:30:00', '12/20/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161220LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161220LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161220LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161220LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161220LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161220LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161220LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161220LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/21/2016 11:30:00', '12/21/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161221LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161221LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161221LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161221LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161221LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161221LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161221LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161221LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/23/2016 11:30:00', '12/23/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161223LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161223LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161223LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161223LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161223LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161223LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161223LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161223LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/24/2016 11:30:00', '12/24/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161224LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161224LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161224LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161224LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161224LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161224LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161224LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161224LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/27/2016 11:30:00', '12/27/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161227LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161227LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161227LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161227LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161227LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161227LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161227LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161227LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/28/2016 11:30:00', '12/28/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161228LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161228LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161228LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161228LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161228LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161228LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161228LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161228LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/30/2016 11:30:00', '12/30/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161230LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161230LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161230LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161230LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161230LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161230LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161230LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161230LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/31/2016 11:30:00', '12/31/2016 13:00:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161231LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161231LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161231LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161231LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161231LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161231LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161231LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161231LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/03/2017 11:30:00', '01/03/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170103LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170103LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170103LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170103LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170103LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170103LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170103LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170103LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/04/2017 11:30:00', '01/04/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170104LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170104LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170104LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170104LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170104LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170104LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170104LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170104LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/06/2017 11:30:00', '01/06/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170106LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170106LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170106LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170106LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170106LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170106LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170106LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170106LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/07/2017 11:30:00', '01/07/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170107LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170107LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170107LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170107LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170107LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170107LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170107LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170107LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/10/2017 11:30:00', '01/10/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170110LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170110LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170110LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170110LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170110LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170110LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170110LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170110LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/11/2017 11:30:00', '01/11/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170111LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170111LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170111LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170111LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170111LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170111LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170111LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170111LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/13/2017 11:30:00', '01/13/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170113LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170113LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170113LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170113LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170113LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170113LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170113LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170113LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/14/2017 11:30:00', '01/14/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170114LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170114LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170114LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170114LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170114LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170114LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170114LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170114LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/17/2017 11:30:00', '01/17/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170117LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170117LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170117LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170117LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170117LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170117LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170117LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170117LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/18/2017 11:30:00', '01/18/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170118LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170118LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170118LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170118LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170118LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170118LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170118LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170118LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/20/2017 11:30:00', '01/20/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170120LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170120LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170120LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170120LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170120LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170120LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170120LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170120LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/21/2017 11:30:00', '01/21/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170121LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170121LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170121LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170121LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170121LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170121LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170121LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170121LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/24/2017 11:30:00', '01/24/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170124LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170124LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170124LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170124LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170124LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170124LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170124LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170124LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/25/2017 11:30:00', '01/25/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170125LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170125LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170125LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170125LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170125LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170125LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170125LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170125LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/27/2017 11:30:00', '01/27/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170127LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170127LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170127LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170127LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170127LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170127LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170127LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170127LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/28/2017 11:30:00', '01/28/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170128LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170128LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170128LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170128LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170128LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170128LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170128LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170128LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/31/2017 11:30:00', '01/31/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170131LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170131LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170131LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170131LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170131LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170131LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170131LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170131LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/01/2017 11:30:00', '02/01/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170201LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170201LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170201LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170201LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170201LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170201LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170201LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170201LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/03/2017 11:30:00', '02/03/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170203LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170203LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170203LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170203LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170203LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170203LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170203LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170203LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/04/2017 11:30:00', '02/04/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170204LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170204LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170204LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170204LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170204LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170204LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170204LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170204LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/07/2017 11:30:00', '02/07/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170207LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170207LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170207LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170207LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170207LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170207LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170207LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170207LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/08/2017 11:30:00', '02/08/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170208LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170208LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170208LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170208LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170208LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170208LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170208LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170208LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/10/2017 11:30:00', '02/10/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170210LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170210LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170210LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170210LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170210LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170210LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170210LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170210LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/11/2017 11:30:00', '02/11/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170211LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170211LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170211LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170211LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170211LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170211LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170211LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170211LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/14/2017 11:30:00', '02/14/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170214LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170214LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170214LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170214LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170214LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170214LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170214LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170214LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/15/2017 11:30:00', '02/15/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170215LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170215LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170215LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170215LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170215LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170215LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170215LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170215LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/17/2017 11:30:00', '02/17/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170217LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170217LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170217LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170217LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170217LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170217LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170217LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170217LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/18/2017 11:30:00', '02/18/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170218LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170218LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170218LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170218LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170218LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170218LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170218LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170218LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/21/2017 11:30:00', '02/21/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170221LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170221LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170221LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170221LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170221LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170221LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170221LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170221LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/22/2017 11:30:00', '02/22/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170222LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170222LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170222LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170222LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170222LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170222LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170222LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170222LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/24/2017 11:30:00', '02/24/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170224LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170224LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170224LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170224LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170224LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170224LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170224LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170224LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/25/2017 11:30:00', '02/25/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170225LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170225LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170225LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170225LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170225LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170225LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170225LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170225LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/28/2017 11:30:00', '02/28/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170228LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170228LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170228LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170228LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170228LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170228LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170228LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170228LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/01/2017 11:30:00', '03/01/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170301LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170301LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170301LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170301LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170301LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170301LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170301LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170301LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/03/2017 11:30:00', '03/03/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170303LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170303LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170303LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170303LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170303LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170303LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170303LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170303LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/04/2017 11:30:00', '03/04/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170304LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170304LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170304LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170304LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170304LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170304LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170304LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170304LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/07/2017 11:30:00', '03/07/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170307LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170307LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170307LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170307LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170307LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170307LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170307LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170307LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/08/2017 11:30:00', '03/08/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170308LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170308LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170308LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170308LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170308LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170308LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170308LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170308LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/10/2017 11:30:00', '03/10/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170310LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170310LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170310LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170310LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170310LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170310LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170310LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170310LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/11/2017 11:30:00', '03/11/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170311LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170311LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170311LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170311LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170311LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170311LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170311LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170311LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/14/2017 11:30:00', '03/14/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170314LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170314LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170314LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170314LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170314LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170314LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170314LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170314LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/15/2017 11:30:00', '03/15/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170315LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170315LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170315LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170315LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170315LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170315LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170315LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170315LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/17/2017 11:30:00', '03/17/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170317LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170317LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170317LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170317LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170317LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170317LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170317LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170317LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/18/2017 11:30:00', '03/18/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170318LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170318LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170318LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170318LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170318LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170318LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170318LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170318LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/21/2017 11:30:00', '03/21/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170321LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170321LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170321LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170321LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170321LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170321LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170321LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170321LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/22/2017 11:30:00', '03/22/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170322LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170322LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170322LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170322LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170322LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170322LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170322LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170322LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/24/2017 11:30:00', '03/24/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170324LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170324LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170324LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170324LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170324LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170324LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170324LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170324LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/25/2017 11:30:00', '03/25/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170325LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170325LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170325LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170325LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170325LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170325LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170325LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170325LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/28/2017 11:30:00', '03/28/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170328LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170328LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170328LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170328LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170328LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170328LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170328LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170328LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/29/2017 11:30:00', '03/29/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170329LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170329LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170329LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170329LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170329LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170329LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170329LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170329LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/31/2017 11:30:00', '03/31/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170331LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170331LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170331LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170331LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170331LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170331LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170331LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170331LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/01/2017 11:30:00', '04/01/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170401LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170401LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170401LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170401LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170401LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170401LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170401LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170401LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/04/2017 11:30:00', '04/04/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170404LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170404LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170404LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170404LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170404LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170404LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170404LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170404LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/05/2017 11:30:00', '04/05/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170405LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170405LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170405LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170405LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170405LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170405LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170405LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170405LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/07/2017 11:30:00', '04/07/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170407LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170407LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170407LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170407LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170407LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170407LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170407LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170407LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/08/2017 11:30:00', '04/08/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170408LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170408LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170408LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170408LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170408LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170408LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170408LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170408LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/11/2017 11:30:00', '04/11/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170411LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170411LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170411LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170411LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170411LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170411LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170411LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170411LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/12/2017 11:30:00', '04/12/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170412LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170412LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170412LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170412LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170412LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170412LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170412LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170412LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/14/2017 11:30:00', '04/14/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170414LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170414LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170414LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170414LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170414LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170414LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170414LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170414LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/15/2017 11:30:00', '04/15/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170415LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170415LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170415LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170415LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170415LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170415LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170415LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170415LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/18/2017 11:30:00', '04/18/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170418LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170418LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170418LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170418LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170418LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170418LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170418LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170418LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/19/2017 11:30:00', '04/19/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170419LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170419LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170419LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170419LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170419LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170419LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170419LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170419LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/21/2017 11:30:00', '04/21/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170421LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170421LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170421LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170421LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170421LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170421LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170421LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170421LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/22/2017 11:30:00', '04/22/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170422LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170422LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170422LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170422LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170422LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170422LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170422LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170422LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/25/2017 11:30:00', '04/25/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170425LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170425LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170425LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170425LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170425LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170425LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170425LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170425LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/26/2017 11:30:00', '04/26/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170426LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170426LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170426LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170426LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170426LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170426LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170426LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170426LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/28/2017 11:30:00', '04/28/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170428LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170428LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170428LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170428LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170428LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170428LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170428LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170428LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/29/2017 11:30:00', '04/29/2017 13:00:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170429LTNALC9103', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170429LTNALC9103', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170429LTNALC9103', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170429LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170429LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170429LTNALC9103', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170429LTNALC9103', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170429LTNALC9103', 'Internet', 0, 39, 0
EXEC dbo.CreateSector 'LTN', 'ALC', 'Y', 'LTNALC'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/07/2016 11:30:00', '11/07/2016 13:00:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161107LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161107LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161107LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161107LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161107LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161107LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/14/2016 11:30:00', '11/14/2016 13:00:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161114LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161114LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161114LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161114LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161114LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161114LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/21/2016 11:30:00', '11/21/2016 13:00:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161121LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161121LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161121LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161121LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161121LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161121LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/28/2016 11:30:00', '11/28/2016 13:00:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161128LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161128LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161128LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161128LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161128LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161128LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/05/2016 11:30:00', '12/05/2016 13:00:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161205LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161205LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161205LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161205LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161205LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161205LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/12/2016 11:30:00', '12/12/2016 13:00:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161212LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161212LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161212LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161212LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161212LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161212LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/19/2016 11:30:00', '12/19/2016 13:00:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161219LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161219LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161219LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161219LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161219LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161219LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/26/2016 11:30:00', '12/26/2016 13:00:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161226LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161226LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161226LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161226LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161226LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161226LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/02/2017 11:30:00', '01/02/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170102LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170102LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170102LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170102LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170102LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170102LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/09/2017 11:30:00', '01/09/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170109LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170109LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170109LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170109LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170109LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170109LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/16/2017 11:30:00', '01/16/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170116LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170116LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170116LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170116LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170116LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170116LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/23/2017 11:30:00', '01/23/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170123LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170123LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170123LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170123LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170123LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170123LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/30/2017 11:30:00', '01/30/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170130LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170130LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170130LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170130LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170130LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170130LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/06/2017 11:30:00', '02/06/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170206LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170206LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170206LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170206LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170206LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170206LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/13/2017 11:30:00', '02/13/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170213LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170213LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170213LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170213LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170213LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170213LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/20/2017 11:30:00', '02/20/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170220LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170220LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170220LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170220LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170220LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170220LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/27/2017 11:30:00', '02/27/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170227LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170227LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170227LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170227LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170227LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170227LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/06/2017 11:30:00', '03/06/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170306LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170306LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170306LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170306LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170306LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170306LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/13/2017 11:30:00', '03/13/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170313LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170313LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170313LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170313LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170313LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170313LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/20/2017 11:30:00', '03/20/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170320LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170320LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170320LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170320LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170320LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170320LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/27/2017 11:30:00', '03/27/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170327LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170327LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170327LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170327LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170327LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170327LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/03/2017 11:30:00', '04/03/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170403LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170403LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170403LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170403LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170403LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170403LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/10/2017 11:30:00', '04/10/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170410LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170410LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170410LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170410LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170410LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170410LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/17/2017 11:30:00', '04/17/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170417LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170417LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170417LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170417LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170417LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170417LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/24/2017 11:30:00', '04/24/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170424LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170424LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170424LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170424LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170424LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170424LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '05/01/2017 11:30:00', '05/01/2017 13:00:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170501LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170501LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170501LTNALC9103', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170501LTNALC9103', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170501LTNALC9103', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170501LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateSector 'LTN', 'ALC', 'Y', 'LTNALC'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/03/2016 11:30:00', '11/03/2016 13:00:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161103LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161103LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161103LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161103LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161103LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161103LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161103LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161103LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/10/2016 11:30:00', '11/10/2016 13:00:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161110LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161110LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161110LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161110LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161110LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161110LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161110LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161110LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/17/2016 11:30:00', '11/17/2016 13:00:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161117LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161117LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161117LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161117LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161117LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161117LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161117LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161117LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '11/24/2016 11:30:00', '11/24/2016 13:00:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161124LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161124LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161124LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161124LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161124LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161124LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161124LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161124LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/01/2016 11:30:00', '12/01/2016 13:00:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161201LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161201LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161201LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161201LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161201LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161201LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161201LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161201LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/08/2016 11:30:00', '12/08/2016 13:00:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161208LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161208LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161208LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161208LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161208LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161208LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161208LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161208LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/15/2016 11:30:00', '12/15/2016 13:00:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161215LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161215LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161215LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161215LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161215LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161215LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161215LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161215LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/22/2016 11:30:00', '12/22/2016 13:00:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161222LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161222LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161222LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161222LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161222LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161222LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161222LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161222LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '12/29/2016 11:30:00', '12/29/2016 13:00:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161229LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161229LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161229LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161229LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161229LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161229LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161229LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161229LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/05/2017 11:30:00', '01/05/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170105LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170105LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170105LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170105LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170105LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170105LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170105LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170105LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/12/2017 11:30:00', '01/12/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170112LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170112LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170112LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170112LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170112LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170112LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170112LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170112LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/19/2017 11:30:00', '01/19/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170119LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170119LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170119LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170119LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170119LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170119LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170119LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170119LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '01/26/2017 11:30:00', '01/26/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170126LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170126LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170126LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170126LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170126LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170126LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170126LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170126LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/02/2017 11:30:00', '02/02/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170202LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170202LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170202LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170202LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170202LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170202LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170202LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170202LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/09/2017 11:30:00', '02/09/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170209LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170209LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170209LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170209LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170209LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170209LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170209LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170209LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/16/2017 11:30:00', '02/16/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170216LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170216LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170216LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170216LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170216LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170216LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170216LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170216LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '02/23/2017 11:30:00', '02/23/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170223LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170223LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170223LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170223LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170223LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170223LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170223LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170223LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/02/2017 11:30:00', '03/02/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170302LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170302LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170302LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170302LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170302LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170302LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170302LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170302LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/09/2017 11:30:00', '03/09/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170309LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170309LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170309LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170309LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170309LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170309LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170309LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170309LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/16/2017 11:30:00', '03/16/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170316LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170316LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170316LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170316LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170316LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170316LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170316LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170316LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/23/2017 11:30:00', '03/23/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170323LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170323LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170323LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170323LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170323LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170323LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170323LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170323LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '03/30/2017 11:30:00', '03/30/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170330LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170330LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170330LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170330LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170330LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170330LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170330LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170330LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/06/2017 11:30:00', '04/06/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170406LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170406LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170406LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170406LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170406LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170406LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170406LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170406LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/13/2017 11:30:00', '04/13/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170413LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170413LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170413LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170413LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170413LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170413LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170413LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170413LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/20/2017 11:30:00', '04/20/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170420LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170420LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170420LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170420LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170420LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170420LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170420LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170420LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9103      ', '04/27/2017 11:30:00', '04/27/2017 13:00:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170427LTNALC9103', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170427LTNALC9103', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170427LTNALC9103', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170427LTNALC9103', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170427LTNALC9103', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170427LTNALC9103', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170427LTNALC9103', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170427LTNALC9103', 'Internet', 60, 79, 0
EXEC dbo.CreateSector 'ALC', 'LTN', 'Y', 'ALCLTN'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/03/2016 13:45:00', '11/03/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161103ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161103ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161103ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161103ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161103ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161103ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161103ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161103ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/04/2016 13:45:00', '11/04/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161104ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161104ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161104ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161104ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161104ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161104ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161104ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161104ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/05/2016 13:45:00', '11/05/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161105ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161105ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161105ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161105ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161105ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161105ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161105ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161105ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/07/2016 13:45:00', '11/07/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161107ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161107ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161107ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161107ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161107ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161107ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161107ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161107ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/08/2016 13:45:00', '11/08/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161108ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161108ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161108ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161108ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161108ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161108ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161108ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161108ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/10/2016 13:45:00', '11/10/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161110ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161110ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161110ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161110ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161110ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161110ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161110ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161110ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/11/2016 13:45:00', '11/11/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161111ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161111ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161111ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161111ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161111ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161111ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161111ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161111ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/12/2016 13:45:00', '11/12/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161112ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161112ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161112ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161112ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161112ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161112ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161112ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161112ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/14/2016 13:45:00', '11/14/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161114ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161114ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161114ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161114ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161114ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161114ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161114ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161114ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/15/2016 13:45:00', '11/15/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161115ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161115ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161115ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161115ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161115ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161115ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161115ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161115ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/17/2016 13:45:00', '11/17/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161117ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161117ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161117ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161117ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161117ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161117ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161117ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161117ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/18/2016 13:45:00', '11/18/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161118ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161118ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161118ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161118ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161118ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161118ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161118ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161118ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/19/2016 13:45:00', '11/19/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161119ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161119ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161119ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161119ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161119ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161119ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161119ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161119ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/21/2016 13:45:00', '11/21/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161121ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161121ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161121ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161121ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161121ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161121ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161121ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161121ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/22/2016 13:45:00', '11/22/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161122ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161122ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161122ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161122ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161122ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161122ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161122ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161122ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/24/2016 13:45:00', '11/24/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161124ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161124ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161124ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161124ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161124ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161124ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161124ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161124ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/25/2016 13:45:00', '11/25/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161125ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161125ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161125ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161125ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161125ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161125ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161125ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161125ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/26/2016 13:45:00', '11/26/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161126ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161126ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161126ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161126ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161126ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161126ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161126ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161126ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/28/2016 13:45:00', '11/28/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161128ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161128ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161128ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161128ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161128ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161128ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161128ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161128ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/29/2016 13:45:00', '11/29/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161129ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161129ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161129ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161129ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161129ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161129ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161129ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161129ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/01/2016 13:45:00', '12/01/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161201ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161201ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161201ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161201ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161201ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161201ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161201ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161201ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/02/2016 13:45:00', '12/02/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161202ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161202ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161202ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161202ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161202ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161202ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161202ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161202ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/03/2016 13:45:00', '12/03/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161203ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161203ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161203ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161203ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161203ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161203ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161203ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161203ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/05/2016 13:45:00', '12/05/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161205ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161205ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161205ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161205ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161205ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161205ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161205ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161205ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/06/2016 13:45:00', '12/06/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161206ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161206ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161206ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161206ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161206ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161206ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161206ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161206ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/08/2016 13:45:00', '12/08/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161208ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161208ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161208ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161208ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161208ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161208ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161208ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161208ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/09/2016 13:45:00', '12/09/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161209ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161209ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161209ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161209ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161209ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161209ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161209ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161209ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/10/2016 13:45:00', '12/10/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161210ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161210ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161210ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161210ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161210ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161210ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161210ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161210ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/12/2016 13:45:00', '12/12/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161212ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161212ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161212ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161212ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161212ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161212ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161212ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161212ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/13/2016 13:45:00', '12/13/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161213ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161213ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161213ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161213ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161213ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161213ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161213ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161213ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/15/2016 13:45:00', '12/15/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161215ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161215ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161215ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161215ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161215ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161215ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161215ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161215ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/16/2016 13:45:00', '12/16/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161216ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161216ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161216ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161216ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161216ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161216ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161216ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161216ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/17/2016 13:45:00', '12/17/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161217ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161217ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161217ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161217ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161217ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161217ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161217ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161217ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/19/2016 13:45:00', '12/19/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161219ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161219ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161219ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161219ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161219ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161219ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161219ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161219ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/20/2016 13:45:00', '12/20/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161220ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161220ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161220ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161220ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161220ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161220ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161220ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161220ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/22/2016 13:45:00', '12/22/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161222ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161222ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161222ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161222ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161222ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161222ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161222ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161222ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/23/2016 13:45:00', '12/23/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161223ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161223ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161223ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161223ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161223ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161223ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161223ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161223ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/24/2016 13:45:00', '12/24/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161224ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161224ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161224ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161224ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161224ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161224ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161224ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161224ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/26/2016 13:45:00', '12/26/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161226ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161226ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161226ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161226ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161226ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161226ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161226ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161226ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/27/2016 13:45:00', '12/27/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161227ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161227ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161227ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161227ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161227ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161227ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161227ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161227ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/29/2016 13:45:00', '12/29/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161229ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161229ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161229ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161229ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161229ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161229ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161229ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161229ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/30/2016 13:45:00', '12/30/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161230ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161230ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161230ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161230ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161230ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161230ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161230ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161230ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/31/2016 13:45:00', '12/31/2016 15:15:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161231ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161231ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161231ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161231ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161231ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161231ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161231ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161231ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/02/2017 13:45:00', '01/02/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170102ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170102ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170102ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170102ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170102ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170102ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170102ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170102ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/03/2017 13:45:00', '01/03/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170103ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170103ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170103ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170103ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170103ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170103ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170103ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170103ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/05/2017 13:45:00', '01/05/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170105ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170105ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170105ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170105ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170105ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170105ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170105ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170105ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/06/2017 13:45:00', '01/06/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170106ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170106ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170106ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170106ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170106ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170106ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170106ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170106ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/07/2017 13:45:00', '01/07/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170107ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170107ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170107ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170107ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170107ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170107ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170107ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170107ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/09/2017 13:45:00', '01/09/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170109ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170109ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170109ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170109ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170109ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170109ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170109ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170109ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/10/2017 13:45:00', '01/10/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170110ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170110ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170110ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170110ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170110ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170110ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170110ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170110ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/12/2017 13:45:00', '01/12/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170112ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170112ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170112ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170112ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170112ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170112ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170112ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170112ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/13/2017 13:45:00', '01/13/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170113ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170113ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170113ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170113ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170113ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170113ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170113ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170113ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/14/2017 13:45:00', '01/14/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170114ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170114ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170114ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170114ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170114ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170114ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170114ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170114ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/16/2017 13:45:00', '01/16/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170116ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170116ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170116ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170116ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170116ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170116ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170116ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170116ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/17/2017 13:45:00', '01/17/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170117ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170117ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170117ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170117ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170117ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170117ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170117ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170117ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/19/2017 13:45:00', '01/19/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170119ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170119ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170119ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170119ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170119ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170119ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170119ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170119ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/20/2017 13:45:00', '01/20/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170120ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170120ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170120ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170120ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170120ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170120ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170120ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170120ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/21/2017 13:45:00', '01/21/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170121ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170121ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170121ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170121ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170121ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170121ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170121ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170121ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/23/2017 13:45:00', '01/23/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170123ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170123ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170123ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170123ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170123ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170123ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170123ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170123ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/24/2017 13:45:00', '01/24/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170124ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170124ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170124ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170124ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170124ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170124ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170124ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170124ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/26/2017 13:45:00', '01/26/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170126ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170126ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170126ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170126ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170126ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170126ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170126ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170126ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/27/2017 13:45:00', '01/27/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170127ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170127ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170127ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170127ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170127ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170127ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170127ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170127ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/28/2017 13:45:00', '01/28/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170128ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170128ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170128ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170128ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170128ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170128ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170128ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170128ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/30/2017 13:45:00', '01/30/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170130ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170130ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170130ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170130ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170130ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170130ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170130ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170130ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/31/2017 13:45:00', '01/31/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170131ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170131ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170131ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170131ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170131ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170131ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170131ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170131ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/02/2017 13:45:00', '02/02/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170202ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170202ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170202ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170202ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170202ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170202ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170202ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170202ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/03/2017 13:45:00', '02/03/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170203ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170203ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170203ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170203ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170203ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170203ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170203ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170203ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/04/2017 13:45:00', '02/04/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170204ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170204ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170204ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170204ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170204ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170204ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170204ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170204ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/06/2017 13:45:00', '02/06/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170206ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170206ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170206ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170206ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170206ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170206ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170206ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170206ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/07/2017 13:45:00', '02/07/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170207ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170207ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170207ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170207ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170207ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170207ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170207ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170207ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/09/2017 13:45:00', '02/09/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170209ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170209ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170209ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170209ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170209ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170209ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170209ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170209ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/10/2017 13:45:00', '02/10/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170210ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170210ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170210ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170210ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170210ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170210ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170210ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170210ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/11/2017 13:45:00', '02/11/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170211ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170211ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170211ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170211ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170211ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170211ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170211ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170211ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/13/2017 13:45:00', '02/13/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170213ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170213ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170213ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170213ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170213ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170213ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170213ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170213ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/14/2017 13:45:00', '02/14/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170214ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170214ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170214ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170214ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170214ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170214ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170214ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170214ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/16/2017 13:45:00', '02/16/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170216ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170216ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170216ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170216ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170216ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170216ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170216ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170216ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/17/2017 13:45:00', '02/17/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170217ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170217ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170217ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170217ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170217ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170217ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170217ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170217ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/18/2017 13:45:00', '02/18/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170218ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170218ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170218ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170218ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170218ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170218ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170218ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170218ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/20/2017 13:45:00', '02/20/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170220ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170220ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170220ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170220ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170220ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170220ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170220ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170220ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/21/2017 13:45:00', '02/21/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170221ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170221ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170221ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170221ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170221ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170221ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170221ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170221ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/23/2017 13:45:00', '02/23/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170223ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170223ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170223ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170223ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170223ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170223ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170223ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170223ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/24/2017 13:45:00', '02/24/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170224ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170224ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170224ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170224ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170224ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170224ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170224ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170224ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/25/2017 13:45:00', '02/25/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170225ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170225ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170225ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170225ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170225ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170225ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170225ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170225ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/27/2017 13:45:00', '02/27/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170227ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170227ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170227ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170227ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170227ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170227ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170227ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170227ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/28/2017 13:45:00', '02/28/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170228ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170228ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170228ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170228ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170228ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170228ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170228ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170228ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/02/2017 13:45:00', '03/02/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170302ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170302ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170302ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170302ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170302ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170302ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170302ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170302ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/03/2017 13:45:00', '03/03/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170303ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170303ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170303ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170303ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170303ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170303ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170303ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170303ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/04/2017 13:45:00', '03/04/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170304ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170304ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170304ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170304ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170304ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170304ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170304ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170304ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/06/2017 13:45:00', '03/06/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170306ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170306ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170306ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170306ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170306ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170306ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170306ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170306ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/07/2017 13:45:00', '03/07/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170307ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170307ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170307ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170307ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170307ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170307ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170307ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170307ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/09/2017 13:45:00', '03/09/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170309ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170309ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170309ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170309ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170309ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170309ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170309ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170309ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/10/2017 13:45:00', '03/10/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170310ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170310ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170310ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170310ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170310ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170310ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170310ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170310ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/11/2017 13:45:00', '03/11/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170311ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170311ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170311ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170311ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170311ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170311ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170311ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170311ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/13/2017 13:45:00', '03/13/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170313ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170313ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170313ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170313ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170313ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170313ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170313ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170313ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/14/2017 13:45:00', '03/14/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170314ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170314ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170314ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170314ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170314ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170314ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170314ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170314ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/16/2017 13:45:00', '03/16/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170316ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170316ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170316ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170316ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170316ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170316ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170316ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170316ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/17/2017 13:45:00', '03/17/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170317ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170317ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170317ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170317ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170317ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170317ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170317ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170317ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/18/2017 13:45:00', '03/18/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170318ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170318ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170318ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170318ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170318ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170318ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170318ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170318ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/20/2017 13:45:00', '03/20/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170320ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170320ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170320ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170320ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170320ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170320ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170320ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170320ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/21/2017 13:45:00', '03/21/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170321ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170321ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170321ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170321ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170321ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170321ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170321ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170321ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/23/2017 13:45:00', '03/23/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170323ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170323ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170323ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170323ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170323ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170323ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170323ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170323ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/24/2017 13:45:00', '03/24/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170324ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170324ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170324ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170324ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170324ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170324ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170324ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170324ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/25/2017 13:45:00', '03/25/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170325ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170325ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170325ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170325ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170325ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170325ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170325ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170325ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/27/2017 13:45:00', '03/27/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170327ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170327ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170327ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170327ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170327ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170327ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170327ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170327ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/28/2017 13:45:00', '03/28/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170328ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170328ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170328ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170328ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170328ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170328ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170328ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170328ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/30/2017 13:45:00', '03/30/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170330ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170330ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170330ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170330ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170330ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170330ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170330ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170330ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/31/2017 13:45:00', '03/31/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170331ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170331ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170331ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170331ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170331ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170331ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170331ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170331ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/01/2017 13:45:00', '04/01/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170401ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170401ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170401ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170401ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170401ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170401ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170401ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170401ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/03/2017 13:45:00', '04/03/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170403ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170403ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170403ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170403ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170403ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170403ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170403ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170403ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/04/2017 13:45:00', '04/04/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170404ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170404ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170404ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170404ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170404ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170404ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170404ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170404ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/06/2017 13:45:00', '04/06/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170406ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170406ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170406ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170406ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170406ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170406ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170406ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170406ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/07/2017 13:45:00', '04/07/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170407ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170407ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170407ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170407ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170407ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170407ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170407ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170407ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/08/2017 13:45:00', '04/08/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170408ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170408ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170408ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170408ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170408ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170408ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170408ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170408ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/10/2017 13:45:00', '04/10/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170410ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170410ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170410ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170410ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170410ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170410ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170410ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170410ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/11/2017 13:45:00', '04/11/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170411ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170411ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170411ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170411ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170411ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170411ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170411ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170411ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/13/2017 13:45:00', '04/13/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170413ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170413ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170413ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170413ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170413ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170413ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170413ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170413ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/14/2017 13:45:00', '04/14/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170414ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170414ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170414ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170414ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170414ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170414ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170414ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170414ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/15/2017 13:45:00', '04/15/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170415ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170415ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170415ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170415ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170415ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170415ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170415ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170415ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/17/2017 13:45:00', '04/17/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170417ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170417ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170417ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170417ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170417ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170417ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170417ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170417ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/18/2017 13:45:00', '04/18/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170418ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170418ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170418ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170418ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170418ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170418ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170418ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170418ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/20/2017 13:45:00', '04/20/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170420ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170420ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170420ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170420ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170420ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170420ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170420ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170420ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/21/2017 13:45:00', '04/21/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170421ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170421ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170421ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170421ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170421ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170421ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170421ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170421ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/22/2017 13:45:00', '04/22/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170422ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170422ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170422ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170422ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170422ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170422ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170422ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170422ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/24/2017 13:45:00', '04/24/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170424ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170424ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170424ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170424ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170424ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170424ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170424ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170424ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/25/2017 13:45:00', '04/25/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170425ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170425ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170425ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170425ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170425ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170425ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170425ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170425ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/27/2017 13:45:00', '04/27/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170427ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170427ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170427ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170427ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170427ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170427ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170427ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170427ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/28/2017 13:45:00', '04/28/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170428ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170428ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170428ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170428ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170428ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170428ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170428ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170428ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/29/2017 13:45:00', '04/29/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170429ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170429ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170429ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170429ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170429ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170429ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170429ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170429ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '05/01/2017 13:45:00', '05/01/2017 15:15:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170501ALCLTN9104', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170501ALCLTN9104', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170501ALCLTN9104', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170501ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170501ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170501ALCLTN9104', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170501ALCLTN9104', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170501ALCLTN9104', 'Internet', 0, 39, 0
EXEC dbo.CreateSector 'ALC', 'LTN', 'Y', 'ALCLTN'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/02/2016 13:45:00', '11/02/2016 15:15:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161102ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161102ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161102ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161102ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161102ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161102ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/09/2016 13:45:00', '11/09/2016 15:15:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161109ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161109ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161109ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161109ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161109ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161109ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/16/2016 13:45:00', '11/16/2016 15:15:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161116ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161116ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161116ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161116ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161116ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161116ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/23/2016 13:45:00', '11/23/2016 15:15:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161123ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161123ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161123ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161123ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161123ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161123ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/30/2016 13:45:00', '11/30/2016 15:15:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161130ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161130ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161130ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161130ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161130ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161130ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/07/2016 13:45:00', '12/07/2016 15:15:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161207ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161207ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161207ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161207ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161207ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161207ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/14/2016 13:45:00', '12/14/2016 15:15:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161214ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161214ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161214ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161214ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161214ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161214ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/21/2016 13:45:00', '12/21/2016 15:15:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161221ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161221ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161221ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161221ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161221ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161221ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/28/2016 13:45:00', '12/28/2016 15:15:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161228ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161228ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161228ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161228ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161228ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161228ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/04/2017 13:45:00', '01/04/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170104ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170104ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170104ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170104ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170104ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170104ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/11/2017 13:45:00', '01/11/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170111ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170111ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170111ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170111ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170111ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170111ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/18/2017 13:45:00', '01/18/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170118ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170118ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170118ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170118ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170118ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170118ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/25/2017 13:45:00', '01/25/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170125ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170125ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170125ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170125ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170125ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170125ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/01/2017 13:45:00', '02/01/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170201ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170201ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170201ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170201ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170201ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170201ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/08/2017 13:45:00', '02/08/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170208ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170208ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170208ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170208ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170208ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170208ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/15/2017 13:45:00', '02/15/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170215ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170215ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170215ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170215ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170215ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170215ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/22/2017 13:45:00', '02/22/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170222ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170222ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170222ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170222ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170222ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170222ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/01/2017 13:45:00', '03/01/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170301ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170301ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170301ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170301ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170301ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170301ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/08/2017 13:45:00', '03/08/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170308ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170308ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170308ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170308ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170308ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170308ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/15/2017 13:45:00', '03/15/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170315ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170315ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170315ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170315ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170315ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170315ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/22/2017 13:45:00', '03/22/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170322ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170322ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170322ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170322ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170322ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170322ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/29/2017 13:45:00', '03/29/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170329ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170329ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170329ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170329ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170329ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170329ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/05/2017 13:45:00', '04/05/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170405ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170405ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170405ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170405ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170405ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170405ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/12/2017 13:45:00', '04/12/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170412ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170412ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170412ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170412ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170412ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170412ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/19/2017 13:45:00', '04/19/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170419ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170419ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170419ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170419ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170419ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170419ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/26/2017 13:45:00', '04/26/2017 15:15:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170426ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170426ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170426ALCLTN9104', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170426ALCLTN9104', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170426ALCLTN9104', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170426ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateSector 'ALC', 'LTN', 'Y', 'ALCLTN'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/06/2016 13:45:00', '11/06/2016 15:15:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161106ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161106ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161106ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161106ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161106ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161106ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161106ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161106ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/13/2016 13:45:00', '11/13/2016 15:15:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161113ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161113ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161113ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161113ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161113ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161113ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161113ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161113ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/20/2016 13:45:00', '11/20/2016 15:15:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161120ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161120ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161120ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161120ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161120ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161120ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161120ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161120ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '11/27/2016 13:45:00', '11/27/2016 15:15:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161127ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161127ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161127ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161127ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161127ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161127ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161127ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161127ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/04/2016 13:45:00', '12/04/2016 15:15:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161204ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161204ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161204ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161204ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161204ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161204ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161204ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161204ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/11/2016 13:45:00', '12/11/2016 15:15:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161211ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161211ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161211ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161211ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161211ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161211ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161211ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161211ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/18/2016 13:45:00', '12/18/2016 15:15:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161218ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161218ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161218ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161218ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161218ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161218ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161218ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161218ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '12/25/2016 13:45:00', '12/25/2016 15:15:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161225ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161225ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161225ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161225ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161225ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161225ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161225ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161225ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/01/2017 13:45:00', '01/01/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170101ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170101ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170101ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170101ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170101ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170101ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170101ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170101ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/08/2017 13:45:00', '01/08/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170108ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170108ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170108ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170108ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170108ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170108ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170108ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170108ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/15/2017 13:45:00', '01/15/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170115ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170115ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170115ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170115ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170115ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170115ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170115ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170115ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/22/2017 13:45:00', '01/22/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170122ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170122ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170122ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170122ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170122ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170122ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170122ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170122ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '01/29/2017 13:45:00', '01/29/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170129ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170129ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170129ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170129ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170129ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170129ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170129ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170129ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/05/2017 13:45:00', '02/05/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170205ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170205ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170205ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170205ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170205ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170205ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170205ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170205ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/12/2017 13:45:00', '02/12/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170212ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170212ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170212ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170212ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170212ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170212ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170212ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170212ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/19/2017 13:45:00', '02/19/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170219ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170219ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170219ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170219ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170219ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170219ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170219ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170219ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '02/26/2017 13:45:00', '02/26/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170226ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170226ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170226ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170226ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170226ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170226ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170226ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170226ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/05/2017 13:45:00', '03/05/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170305ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170305ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170305ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170305ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170305ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170305ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170305ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170305ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/12/2017 13:45:00', '03/12/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170312ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170312ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170312ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170312ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170312ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170312ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170312ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170312ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/19/2017 13:45:00', '03/19/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170319ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170319ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170319ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170319ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170319ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170319ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170319ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170319ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '03/26/2017 13:45:00', '03/26/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170326ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170326ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170326ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170326ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170326ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170326ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170326ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170326ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/02/2017 13:45:00', '04/02/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170402ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170402ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170402ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170402ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170402ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170402ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170402ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170402ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/09/2017 13:45:00', '04/09/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170409ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170409ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170409ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170409ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170409ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170409ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170409ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170409ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/16/2017 13:45:00', '04/16/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170416ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170416ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170416ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170416ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170416ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170416ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170416ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170416ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/23/2017 13:45:00', '04/23/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170423ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170423ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170423ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170423ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170423ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170423ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170423ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170423ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9104      ', '04/30/2017 13:45:00', '04/30/2017 15:15:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170430ALCLTN9104', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170430ALCLTN9104', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170430ALCLTN9104', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170430ALCLTN9104', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170430ALCLTN9104', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170430ALCLTN9104', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170430ALCLTN9104', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170430ALCLTN9104', 'Internet', 60, 79, 0
EXEC dbo.CreateSector 'LTN', 'ALC', 'Y', 'LTNALC'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/02/2016 16:00:00', '11/02/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161102LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161102LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161102LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161102LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161102LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161102LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161102LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161102LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/03/2016 16:00:00', '11/03/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161103LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161103LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161103LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161103LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161103LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161103LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161103LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161103LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/04/2016 16:00:00', '11/04/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161104LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161104LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161104LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161104LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161104LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161104LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161104LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161104LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/05/2016 16:00:00', '11/05/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161105LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161105LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161105LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161105LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161105LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161105LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161105LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161105LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/09/2016 16:00:00', '11/09/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161109LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161109LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161109LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161109LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161109LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161109LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161109LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161109LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/10/2016 16:00:00', '11/10/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161110LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161110LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161110LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161110LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161110LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161110LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161110LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161110LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/11/2016 16:00:00', '11/11/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161111LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161111LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161111LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161111LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161111LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161111LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161111LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161111LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/12/2016 16:00:00', '11/12/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161112LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161112LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161112LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161112LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161112LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161112LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161112LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161112LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/16/2016 16:00:00', '11/16/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161116LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161116LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161116LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161116LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161116LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161116LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161116LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161116LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/17/2016 16:00:00', '11/17/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161117LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161117LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161117LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161117LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161117LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161117LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161117LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161117LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/18/2016 16:00:00', '11/18/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161118LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161118LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161118LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161118LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161118LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161118LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161118LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161118LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/19/2016 16:00:00', '11/19/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161119LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161119LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161119LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161119LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161119LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161119LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161119LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161119LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/23/2016 16:00:00', '11/23/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161123LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161123LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161123LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161123LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161123LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161123LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161123LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161123LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/24/2016 16:00:00', '11/24/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161124LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161124LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161124LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161124LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161124LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161124LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161124LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161124LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/25/2016 16:00:00', '11/25/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161125LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161125LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161125LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161125LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161125LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161125LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161125LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161125LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/26/2016 16:00:00', '11/26/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161126LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161126LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161126LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161126LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161126LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161126LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161126LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161126LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/30/2016 16:00:00', '11/30/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161130LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161130LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161130LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161130LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161130LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161130LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161130LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161130LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/01/2016 16:00:00', '12/01/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161201LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161201LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161201LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161201LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161201LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161201LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161201LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161201LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/02/2016 16:00:00', '12/02/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161202LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161202LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161202LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161202LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161202LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161202LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161202LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161202LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/03/2016 16:00:00', '12/03/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161203LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161203LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161203LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161203LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161203LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161203LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161203LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161203LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/07/2016 16:00:00', '12/07/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161207LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161207LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161207LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161207LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161207LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161207LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161207LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161207LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/08/2016 16:00:00', '12/08/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161208LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161208LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161208LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161208LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161208LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161208LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161208LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161208LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/09/2016 16:00:00', '12/09/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161209LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161209LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161209LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161209LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161209LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161209LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161209LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161209LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/10/2016 16:00:00', '12/10/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161210LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161210LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161210LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161210LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161210LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161210LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161210LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161210LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/14/2016 16:00:00', '12/14/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161214LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161214LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161214LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161214LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161214LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161214LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161214LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161214LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/15/2016 16:00:00', '12/15/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161215LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161215LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161215LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161215LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161215LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161215LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161215LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161215LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/16/2016 16:00:00', '12/16/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161216LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161216LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161216LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161216LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161216LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161216LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161216LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161216LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/17/2016 16:00:00', '12/17/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161217LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161217LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161217LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161217LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161217LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161217LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161217LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161217LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/21/2016 16:00:00', '12/21/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161221LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161221LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161221LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161221LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161221LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161221LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161221LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161221LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/22/2016 16:00:00', '12/22/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161222LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161222LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161222LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161222LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161222LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161222LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161222LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161222LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/23/2016 16:00:00', '12/23/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161223LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161223LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161223LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161223LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161223LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161223LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161223LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161223LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/24/2016 16:00:00', '12/24/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161224LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161224LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161224LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161224LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161224LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161224LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161224LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161224LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/28/2016 16:00:00', '12/28/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161228LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161228LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161228LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161228LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161228LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161228LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161228LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161228LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/29/2016 16:00:00', '12/29/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161229LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161229LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161229LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161229LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161229LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161229LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161229LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161229LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/30/2016 16:00:00', '12/30/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161230LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161230LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161230LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161230LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161230LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161230LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161230LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161230LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/31/2016 16:00:00', '12/31/2016 17:30:00', 'LTN', 'ALC', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161231LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161231LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161231LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161231LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161231LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161231LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161231LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161231LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/04/2017 16:00:00', '01/04/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170104LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170104LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170104LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170104LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170104LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170104LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170104LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170104LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/05/2017 16:00:00', '01/05/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170105LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170105LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170105LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170105LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170105LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170105LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170105LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170105LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/06/2017 16:00:00', '01/06/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170106LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170106LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170106LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170106LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170106LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170106LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170106LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170106LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/07/2017 16:00:00', '01/07/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170107LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170107LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170107LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170107LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170107LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170107LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170107LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170107LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/11/2017 16:00:00', '01/11/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170111LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170111LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170111LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170111LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170111LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170111LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170111LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170111LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/12/2017 16:00:00', '01/12/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170112LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170112LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170112LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170112LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170112LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170112LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170112LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170112LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/13/2017 16:00:00', '01/13/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170113LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170113LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170113LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170113LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170113LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170113LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170113LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170113LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/14/2017 16:00:00', '01/14/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170114LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170114LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170114LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170114LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170114LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170114LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170114LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170114LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/18/2017 16:00:00', '01/18/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170118LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170118LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170118LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170118LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170118LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170118LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170118LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170118LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/19/2017 16:00:00', '01/19/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170119LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170119LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170119LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170119LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170119LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170119LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170119LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170119LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/20/2017 16:00:00', '01/20/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170120LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170120LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170120LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170120LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170120LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170120LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170120LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170120LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/21/2017 16:00:00', '01/21/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170121LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170121LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170121LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170121LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170121LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170121LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170121LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170121LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/25/2017 16:00:00', '01/25/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170125LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170125LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170125LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170125LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170125LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170125LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170125LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170125LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/26/2017 16:00:00', '01/26/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170126LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170126LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170126LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170126LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170126LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170126LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170126LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170126LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/27/2017 16:00:00', '01/27/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170127LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170127LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170127LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170127LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170127LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170127LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170127LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170127LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/28/2017 16:00:00', '01/28/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170128LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170128LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170128LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170128LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170128LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170128LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170128LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170128LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/01/2017 16:00:00', '02/01/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170201LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170201LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170201LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170201LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170201LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170201LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170201LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170201LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/02/2017 16:00:00', '02/02/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170202LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170202LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170202LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170202LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170202LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170202LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170202LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170202LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/03/2017 16:00:00', '02/03/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170203LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170203LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170203LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170203LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170203LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170203LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170203LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170203LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/04/2017 16:00:00', '02/04/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170204LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170204LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170204LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170204LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170204LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170204LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170204LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170204LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/08/2017 16:00:00', '02/08/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170208LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170208LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170208LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170208LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170208LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170208LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170208LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170208LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/09/2017 16:00:00', '02/09/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170209LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170209LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170209LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170209LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170209LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170209LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170209LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170209LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/10/2017 16:00:00', '02/10/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170210LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170210LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170210LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170210LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170210LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170210LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170210LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170210LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/11/2017 16:00:00', '02/11/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170211LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170211LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170211LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170211LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170211LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170211LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170211LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170211LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/15/2017 16:00:00', '02/15/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170215LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170215LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170215LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170215LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170215LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170215LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170215LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170215LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/16/2017 16:00:00', '02/16/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170216LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170216LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170216LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170216LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170216LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170216LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170216LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170216LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/17/2017 16:00:00', '02/17/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170217LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170217LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170217LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170217LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170217LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170217LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170217LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170217LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/18/2017 16:00:00', '02/18/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170218LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170218LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170218LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170218LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170218LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170218LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170218LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170218LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/22/2017 16:00:00', '02/22/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170222LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170222LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170222LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170222LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170222LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170222LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170222LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170222LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/23/2017 16:00:00', '02/23/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170223LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170223LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170223LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170223LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170223LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170223LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170223LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170223LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/24/2017 16:00:00', '02/24/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170224LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170224LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170224LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170224LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170224LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170224LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170224LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170224LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/25/2017 16:00:00', '02/25/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170225LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170225LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170225LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170225LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170225LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170225LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170225LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170225LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/01/2017 16:00:00', '03/01/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170301LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170301LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170301LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170301LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170301LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170301LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170301LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170301LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/02/2017 16:00:00', '03/02/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170302LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170302LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170302LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170302LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170302LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170302LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170302LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170302LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/03/2017 16:00:00', '03/03/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170303LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170303LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170303LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170303LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170303LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170303LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170303LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170303LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/04/2017 16:00:00', '03/04/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170304LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170304LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170304LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170304LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170304LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170304LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170304LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170304LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/08/2017 16:00:00', '03/08/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170308LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170308LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170308LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170308LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170308LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170308LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170308LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170308LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/09/2017 16:00:00', '03/09/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170309LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170309LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170309LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170309LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170309LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170309LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170309LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170309LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/10/2017 16:00:00', '03/10/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170310LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170310LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170310LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170310LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170310LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170310LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170310LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170310LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/11/2017 16:00:00', '03/11/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170311LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170311LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170311LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170311LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170311LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170311LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170311LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170311LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/15/2017 16:00:00', '03/15/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170315LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170315LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170315LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170315LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170315LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170315LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170315LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170315LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/16/2017 16:00:00', '03/16/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170316LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170316LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170316LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170316LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170316LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170316LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170316LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170316LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/17/2017 16:00:00', '03/17/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170317LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170317LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170317LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170317LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170317LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170317LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170317LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170317LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/18/2017 16:00:00', '03/18/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170318LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170318LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170318LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170318LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170318LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170318LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170318LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170318LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/22/2017 16:00:00', '03/22/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170322LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170322LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170322LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170322LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170322LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170322LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170322LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170322LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/23/2017 16:00:00', '03/23/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170323LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170323LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170323LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170323LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170323LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170323LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170323LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170323LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/24/2017 16:00:00', '03/24/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170324LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170324LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170324LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170324LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170324LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170324LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170324LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170324LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/25/2017 16:00:00', '03/25/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170325LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170325LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170325LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170325LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170325LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170325LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170325LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170325LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/29/2017 16:00:00', '03/29/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170329LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170329LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170329LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170329LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170329LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170329LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170329LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170329LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/30/2017 16:00:00', '03/30/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170330LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170330LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170330LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170330LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170330LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170330LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170330LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170330LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/31/2017 16:00:00', '03/31/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170331LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170331LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170331LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170331LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170331LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170331LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170331LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170331LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/01/2017 16:00:00', '04/01/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170401LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170401LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170401LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170401LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170401LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170401LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170401LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170401LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/05/2017 16:00:00', '04/05/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170405LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170405LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170405LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170405LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170405LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170405LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170405LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170405LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/06/2017 16:00:00', '04/06/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170406LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170406LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170406LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170406LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170406LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170406LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170406LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170406LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/07/2017 16:00:00', '04/07/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170407LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170407LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170407LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170407LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170407LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170407LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170407LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170407LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/08/2017 16:00:00', '04/08/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170408LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170408LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170408LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170408LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170408LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170408LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170408LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170408LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/12/2017 16:00:00', '04/12/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170412LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170412LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170412LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170412LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170412LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170412LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170412LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170412LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/13/2017 16:00:00', '04/13/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170413LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170413LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170413LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170413LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170413LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170413LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170413LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170413LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/14/2017 16:00:00', '04/14/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170414LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170414LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170414LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170414LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170414LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170414LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170414LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170414LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/15/2017 16:00:00', '04/15/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170415LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170415LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170415LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170415LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170415LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170415LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170415LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170415LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/19/2017 16:00:00', '04/19/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170419LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170419LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170419LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170419LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170419LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170419LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170419LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170419LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/20/2017 16:00:00', '04/20/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170420LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170420LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170420LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170420LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170420LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170420LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170420LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170420LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/21/2017 16:00:00', '04/21/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170421LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170421LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170421LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170421LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170421LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170421LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170421LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170421LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/22/2017 16:00:00', '04/22/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170422LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170422LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170422LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170422LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170422LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170422LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170422LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170422LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/26/2017 16:00:00', '04/26/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170426LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170426LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170426LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170426LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170426LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170426LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170426LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170426LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/27/2017 16:00:00', '04/27/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170427LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170427LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170427LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170427LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170427LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170427LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170427LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170427LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/28/2017 16:00:00', '04/28/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170428LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170428LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170428LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170428LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170428LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170428LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170428LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170428LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/29/2017 16:00:00', '04/29/2017 17:30:00', 'LTN', 'ALC', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170429LTNALC9105', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170429LTNALC9105', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170429LTNALC9105', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170429LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170429LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170429LTNALC9105', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170429LTNALC9105', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170429LTNALC9105', 'Internet', 0, 39, 0
EXEC dbo.CreateSector 'LTN', 'ALC', 'Y', 'LTNALC'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/07/2016 16:00:00', '11/07/2016 17:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161107LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161107LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161107LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161107LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161107LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161107LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/14/2016 16:00:00', '11/14/2016 17:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161114LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161114LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161114LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161114LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161114LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161114LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/21/2016 16:00:00', '11/21/2016 17:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161121LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161121LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161121LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161121LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161121LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161121LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/28/2016 16:00:00', '11/28/2016 17:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161128LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161128LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161128LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161128LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161128LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161128LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/05/2016 16:00:00', '12/05/2016 17:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161205LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161205LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161205LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161205LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161205LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161205LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/12/2016 16:00:00', '12/12/2016 17:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161212LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161212LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161212LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161212LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161212LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161212LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/19/2016 16:00:00', '12/19/2016 17:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161219LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161219LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161219LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161219LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161219LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161219LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/26/2016 16:00:00', '12/26/2016 17:30:00', 'LTN', 'ALC', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161226LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161226LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161226LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161226LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161226LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161226LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/02/2017 16:00:00', '01/02/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170102LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170102LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170102LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170102LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170102LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170102LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/09/2017 16:00:00', '01/09/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170109LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170109LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170109LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170109LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170109LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170109LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/16/2017 16:00:00', '01/16/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170116LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170116LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170116LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170116LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170116LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170116LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/23/2017 16:00:00', '01/23/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170123LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170123LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170123LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170123LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170123LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170123LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/30/2017 16:00:00', '01/30/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170130LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170130LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170130LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170130LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170130LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170130LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/06/2017 16:00:00', '02/06/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170206LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170206LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170206LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170206LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170206LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170206LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/13/2017 16:00:00', '02/13/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170213LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170213LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170213LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170213LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170213LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170213LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/20/2017 16:00:00', '02/20/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170220LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170220LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170220LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170220LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170220LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170220LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/27/2017 16:00:00', '02/27/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170227LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170227LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170227LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170227LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170227LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170227LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/06/2017 16:00:00', '03/06/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170306LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170306LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170306LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170306LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170306LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170306LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/13/2017 16:00:00', '03/13/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170313LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170313LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170313LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170313LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170313LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170313LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/20/2017 16:00:00', '03/20/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170320LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170320LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170320LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170320LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170320LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170320LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/27/2017 16:00:00', '03/27/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170327LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170327LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170327LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170327LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170327LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170327LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/03/2017 16:00:00', '04/03/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170403LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170403LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170403LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170403LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170403LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170403LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/10/2017 16:00:00', '04/10/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170410LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170410LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170410LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170410LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170410LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170410LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/17/2017 16:00:00', '04/17/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170417LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170417LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170417LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170417LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170417LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170417LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/24/2017 16:00:00', '04/24/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170424LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170424LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170424LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170424LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170424LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170424LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '05/01/2017 16:00:00', '05/01/2017 17:30:00', 'LTN', 'ALC', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170501LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170501LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170501LTNALC9105', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170501LTNALC9105', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170501LTNALC9105', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170501LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateSector 'LTN', 'ALC', 'Y', 'LTNALC'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/08/2016 16:00:00', '11/08/2016 17:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161108LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161108LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161108LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161108LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161108LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161108LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161108LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161108LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/15/2016 16:00:00', '11/15/2016 17:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161115LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161115LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161115LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161115LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161115LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161115LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161115LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161115LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/22/2016 16:00:00', '11/22/2016 17:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161122LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161122LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161122LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161122LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161122LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161122LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161122LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161122LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '11/29/2016 16:00:00', '11/29/2016 17:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161129LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161129LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161129LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161129LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161129LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161129LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161129LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161129LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/06/2016 16:00:00', '12/06/2016 17:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161206LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161206LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161206LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161206LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161206LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161206LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161206LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161206LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/13/2016 16:00:00', '12/13/2016 17:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161213LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161213LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161213LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161213LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161213LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161213LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161213LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161213LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/20/2016 16:00:00', '12/20/2016 17:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161220LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161220LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161220LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161220LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161220LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161220LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161220LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161220LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '12/27/2016 16:00:00', '12/27/2016 17:30:00', 'LTN', 'ALC', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161227LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161227LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161227LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161227LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161227LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161227LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161227LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161227LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/03/2017 16:00:00', '01/03/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170103LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170103LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170103LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170103LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170103LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170103LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170103LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170103LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/10/2017 16:00:00', '01/10/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170110LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170110LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170110LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170110LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170110LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170110LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170110LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170110LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/17/2017 16:00:00', '01/17/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170117LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170117LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170117LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170117LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170117LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170117LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170117LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170117LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/24/2017 16:00:00', '01/24/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170124LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170124LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170124LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170124LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170124LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170124LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170124LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170124LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '01/31/2017 16:00:00', '01/31/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170131LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170131LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170131LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170131LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170131LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170131LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170131LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170131LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/07/2017 16:00:00', '02/07/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170207LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170207LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170207LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170207LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170207LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170207LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170207LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170207LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/14/2017 16:00:00', '02/14/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170214LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170214LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170214LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170214LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170214LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170214LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170214LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170214LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/21/2017 16:00:00', '02/21/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170221LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170221LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170221LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170221LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170221LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170221LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170221LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170221LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '02/28/2017 16:00:00', '02/28/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170228LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170228LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170228LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170228LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170228LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170228LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170228LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170228LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/07/2017 16:00:00', '03/07/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170307LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170307LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170307LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170307LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170307LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170307LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170307LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170307LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/14/2017 16:00:00', '03/14/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170314LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170314LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170314LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170314LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170314LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170314LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170314LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170314LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/21/2017 16:00:00', '03/21/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170321LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170321LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170321LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170321LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170321LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170321LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170321LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170321LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '03/28/2017 16:00:00', '03/28/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170328LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170328LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170328LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170328LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170328LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170328LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170328LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170328LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/04/2017 16:00:00', '04/04/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170404LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170404LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170404LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170404LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170404LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170404LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170404LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170404LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/11/2017 16:00:00', '04/11/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170411LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170411LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170411LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170411LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170411LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170411LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170411LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170411LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/18/2017 16:00:00', '04/18/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170418LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170418LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170418LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170418LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170418LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170418LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170418LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170418LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9105      ', '04/25/2017 16:00:00', '04/25/2017 17:30:00', 'LTN', 'ALC', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170425LTNALC9105', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170425LTNALC9105', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170425LTNALC9105', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170425LTNALC9105', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170425LTNALC9105', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170425LTNALC9105', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170425LTNALC9105', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170425LTNALC9105', 'Internet', 60, 79, 0
EXEC dbo.CreateSector 'ALC', 'LTN', 'Y', 'ALCLTN'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/02/2016 18:15:00', '11/02/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161102ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161102ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161102ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161102ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161102ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161102ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161102ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161102ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/03/2016 18:15:00', '11/03/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161103ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161103ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161103ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161103ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161103ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161103ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161103ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161103ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/04/2016 18:15:00', '11/04/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161104ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161104ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161104ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161104ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161104ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161104ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161104ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161104ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/07/2016 18:15:00', '11/07/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161107ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161107ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161107ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161107ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161107ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161107ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161107ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161107ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/08/2016 18:15:00', '11/08/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161108ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161108ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161108ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161108ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161108ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161108ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161108ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161108ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/09/2016 18:15:00', '11/09/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161109ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161109ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161109ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161109ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161109ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161109ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161109ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161109ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/10/2016 18:15:00', '11/10/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161110ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161110ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161110ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161110ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161110ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161110ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161110ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161110ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/11/2016 18:15:00', '11/11/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161111ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161111ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161111ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161111ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161111ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161111ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161111ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161111ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/14/2016 18:15:00', '11/14/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161114ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161114ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161114ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161114ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161114ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161114ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161114ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161114ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/15/2016 18:15:00', '11/15/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161115ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161115ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161115ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161115ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161115ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161115ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161115ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161115ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/16/2016 18:15:00', '11/16/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161116ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161116ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161116ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161116ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161116ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161116ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161116ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161116ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/17/2016 18:15:00', '11/17/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161117ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161117ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161117ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161117ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161117ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161117ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161117ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161117ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/18/2016 18:15:00', '11/18/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161118ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161118ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161118ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161118ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161118ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161118ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161118ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161118ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/21/2016 18:15:00', '11/21/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161121ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161121ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161121ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161121ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161121ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161121ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161121ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161121ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/22/2016 18:15:00', '11/22/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161122ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161122ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161122ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161122ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161122ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161122ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161122ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161122ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/23/2016 18:15:00', '11/23/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161123ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161123ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161123ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161123ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161123ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161123ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161123ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161123ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/24/2016 18:15:00', '11/24/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161124ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161124ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161124ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161124ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161124ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161124ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161124ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161124ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/25/2016 18:15:00', '11/25/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161125ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161125ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161125ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161125ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161125ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161125ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161125ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161125ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/28/2016 18:15:00', '11/28/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161128ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161128ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161128ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161128ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161128ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161128ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161128ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161128ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/29/2016 18:15:00', '11/29/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161129ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161129ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161129ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161129ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161129ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161129ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161129ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161129ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/30/2016 18:15:00', '11/30/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161130ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161130ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161130ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161130ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161130ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161130ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161130ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161130ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/01/2016 18:15:00', '12/01/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161201ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161201ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161201ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161201ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161201ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161201ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161201ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161201ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/02/2016 18:15:00', '12/02/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161202ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161202ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161202ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161202ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161202ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161202ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161202ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161202ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/05/2016 18:15:00', '12/05/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161205ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161205ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161205ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161205ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161205ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161205ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161205ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161205ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/06/2016 18:15:00', '12/06/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161206ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161206ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161206ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161206ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161206ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161206ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161206ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161206ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/07/2016 18:15:00', '12/07/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161207ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161207ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161207ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161207ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161207ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161207ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161207ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161207ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/08/2016 18:15:00', '12/08/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161208ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161208ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161208ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161208ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161208ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161208ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161208ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161208ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/09/2016 18:15:00', '12/09/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161209ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161209ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161209ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161209ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161209ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161209ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161209ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161209ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/12/2016 18:15:00', '12/12/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161212ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161212ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161212ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161212ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161212ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161212ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161212ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161212ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/13/2016 18:15:00', '12/13/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161213ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161213ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161213ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161213ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161213ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161213ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161213ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161213ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/14/2016 18:15:00', '12/14/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161214ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161214ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161214ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161214ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161214ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161214ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161214ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161214ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/15/2016 18:15:00', '12/15/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161215ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161215ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161215ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161215ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161215ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161215ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161215ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161215ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/16/2016 18:15:00', '12/16/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161216ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161216ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161216ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161216ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161216ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161216ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161216ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161216ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/19/2016 18:15:00', '12/19/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161219ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161219ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161219ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161219ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161219ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161219ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161219ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161219ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/20/2016 18:15:00', '12/20/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161220ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161220ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161220ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161220ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161220ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161220ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161220ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161220ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/21/2016 18:15:00', '12/21/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161221ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161221ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161221ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161221ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161221ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161221ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161221ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161221ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/22/2016 18:15:00', '12/22/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161222ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161222ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161222ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161222ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161222ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161222ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161222ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161222ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/23/2016 18:15:00', '12/23/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161223ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161223ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161223ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161223ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161223ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161223ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161223ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161223ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/26/2016 18:15:00', '12/26/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161226ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161226ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161226ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161226ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161226ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161226ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161226ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161226ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/27/2016 18:15:00', '12/27/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161227ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161227ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161227ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161227ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161227ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161227ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161227ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161227ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/28/2016 18:15:00', '12/28/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161228ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161228ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161228ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161228ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161228ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161228ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161228ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161228ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/29/2016 18:15:00', '12/29/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161229ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161229ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161229ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161229ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161229ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161229ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161229ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161229ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/30/2016 18:15:00', '12/30/2016 19:45:00', 'ALC', 'LTN', 0, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161230ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161230ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161230ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161230ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161230ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161230ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161230ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161230ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/02/2017 18:15:00', '01/02/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170102ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170102ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170102ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170102ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170102ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170102ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170102ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170102ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/03/2017 18:15:00', '01/03/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170103ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170103ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170103ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170103ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170103ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170103ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170103ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170103ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/04/2017 18:15:00', '01/04/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170104ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170104ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170104ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170104ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170104ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170104ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170104ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170104ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/05/2017 18:15:00', '01/05/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170105ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170105ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170105ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170105ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170105ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170105ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170105ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170105ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/06/2017 18:15:00', '01/06/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170106ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170106ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170106ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170106ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170106ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170106ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170106ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170106ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/09/2017 18:15:00', '01/09/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170109ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170109ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170109ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170109ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170109ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170109ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170109ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170109ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/10/2017 18:15:00', '01/10/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170110ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170110ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170110ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170110ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170110ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170110ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170110ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170110ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/11/2017 18:15:00', '01/11/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170111ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170111ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170111ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170111ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170111ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170111ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170111ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170111ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/12/2017 18:15:00', '01/12/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170112ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170112ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170112ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170112ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170112ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170112ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170112ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170112ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/13/2017 18:15:00', '01/13/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170113ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170113ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170113ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170113ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170113ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170113ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170113ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170113ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/16/2017 18:15:00', '01/16/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170116ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170116ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170116ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170116ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170116ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170116ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170116ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170116ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/17/2017 18:15:00', '01/17/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170117ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170117ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170117ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170117ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170117ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170117ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170117ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170117ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/18/2017 18:15:00', '01/18/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170118ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170118ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170118ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170118ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170118ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170118ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170118ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170118ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/19/2017 18:15:00', '01/19/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170119ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170119ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170119ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170119ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170119ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170119ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170119ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170119ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/20/2017 18:15:00', '01/20/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170120ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170120ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170120ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170120ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170120ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170120ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170120ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170120ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/23/2017 18:15:00', '01/23/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170123ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170123ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170123ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170123ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170123ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170123ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170123ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170123ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/24/2017 18:15:00', '01/24/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170124ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170124ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170124ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170124ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170124ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170124ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170124ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170124ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/25/2017 18:15:00', '01/25/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170125ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170125ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170125ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170125ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170125ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170125ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170125ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170125ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/26/2017 18:15:00', '01/26/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170126ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170126ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170126ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170126ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170126ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170126ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170126ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170126ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/27/2017 18:15:00', '01/27/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170127ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170127ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170127ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170127ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170127ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170127ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170127ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170127ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/30/2017 18:15:00', '01/30/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170130ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170130ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170130ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170130ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170130ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170130ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170130ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170130ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/31/2017 18:15:00', '01/31/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170131ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170131ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170131ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170131ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170131ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170131ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170131ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170131ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/01/2017 18:15:00', '02/01/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170201ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170201ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170201ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170201ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170201ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170201ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170201ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170201ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/02/2017 18:15:00', '02/02/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170202ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170202ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170202ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170202ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170202ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170202ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170202ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170202ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/03/2017 18:15:00', '02/03/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170203ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170203ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170203ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170203ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170203ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170203ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170203ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170203ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/06/2017 18:15:00', '02/06/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170206ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170206ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170206ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170206ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170206ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170206ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170206ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170206ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/07/2017 18:15:00', '02/07/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170207ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170207ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170207ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170207ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170207ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170207ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170207ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170207ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/08/2017 18:15:00', '02/08/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170208ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170208ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170208ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170208ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170208ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170208ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170208ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170208ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/09/2017 18:15:00', '02/09/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170209ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170209ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170209ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170209ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170209ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170209ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170209ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170209ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/10/2017 18:15:00', '02/10/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170210ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170210ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170210ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170210ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170210ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170210ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170210ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170210ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/13/2017 18:15:00', '02/13/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170213ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170213ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170213ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170213ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170213ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170213ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170213ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170213ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/14/2017 18:15:00', '02/14/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170214ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170214ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170214ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170214ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170214ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170214ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170214ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170214ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/15/2017 18:15:00', '02/15/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170215ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170215ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170215ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170215ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170215ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170215ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170215ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170215ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/16/2017 18:15:00', '02/16/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170216ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170216ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170216ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170216ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170216ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170216ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170216ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170216ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/17/2017 18:15:00', '02/17/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170217ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170217ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170217ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170217ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170217ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170217ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170217ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170217ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/20/2017 18:15:00', '02/20/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170220ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170220ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170220ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170220ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170220ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170220ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170220ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170220ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/21/2017 18:15:00', '02/21/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170221ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170221ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170221ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170221ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170221ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170221ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170221ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170221ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/22/2017 18:15:00', '02/22/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170222ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170222ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170222ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170222ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170222ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170222ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170222ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170222ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/23/2017 18:15:00', '02/23/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170223ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170223ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170223ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170223ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170223ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170223ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170223ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170223ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/24/2017 18:15:00', '02/24/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170224ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170224ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170224ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170224ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170224ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170224ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170224ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170224ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/27/2017 18:15:00', '02/27/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170227ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170227ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170227ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170227ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170227ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170227ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170227ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170227ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/28/2017 18:15:00', '02/28/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170228ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170228ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170228ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170228ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170228ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170228ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170228ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170228ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/01/2017 18:15:00', '03/01/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170301ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170301ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170301ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170301ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170301ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170301ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170301ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170301ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/02/2017 18:15:00', '03/02/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170302ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170302ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170302ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170302ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170302ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170302ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170302ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170302ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/03/2017 18:15:00', '03/03/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170303ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170303ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170303ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170303ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170303ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170303ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170303ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170303ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/06/2017 18:15:00', '03/06/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170306ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170306ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170306ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170306ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170306ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170306ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170306ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170306ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/07/2017 18:15:00', '03/07/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170307ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170307ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170307ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170307ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170307ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170307ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170307ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170307ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/08/2017 18:15:00', '03/08/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170308ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170308ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170308ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170308ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170308ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170308ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170308ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170308ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/09/2017 18:15:00', '03/09/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170309ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170309ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170309ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170309ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170309ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170309ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170309ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170309ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/10/2017 18:15:00', '03/10/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170310ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170310ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170310ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170310ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170310ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170310ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170310ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170310ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/13/2017 18:15:00', '03/13/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170313ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170313ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170313ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170313ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170313ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170313ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170313ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170313ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/14/2017 18:15:00', '03/14/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170314ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170314ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170314ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170314ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170314ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170314ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170314ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170314ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/15/2017 18:15:00', '03/15/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170315ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170315ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170315ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170315ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170315ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170315ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170315ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170315ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/16/2017 18:15:00', '03/16/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170316ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170316ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170316ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170316ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170316ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170316ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170316ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170316ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/17/2017 18:15:00', '03/17/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170317ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170317ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170317ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170317ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170317ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170317ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170317ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170317ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/20/2017 18:15:00', '03/20/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170320ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170320ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170320ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170320ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170320ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170320ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170320ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170320ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/21/2017 18:15:00', '03/21/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170321ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170321ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170321ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170321ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170321ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170321ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170321ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170321ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/22/2017 18:15:00', '03/22/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170322ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170322ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170322ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170322ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170322ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170322ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170322ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170322ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/23/2017 18:15:00', '03/23/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170323ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170323ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170323ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170323ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170323ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170323ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170323ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170323ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/24/2017 18:15:00', '03/24/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170324ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170324ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170324ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170324ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170324ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170324ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170324ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170324ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/27/2017 18:15:00', '03/27/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170327ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170327ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170327ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170327ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170327ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170327ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170327ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170327ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/28/2017 18:15:00', '03/28/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170328ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170328ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170328ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170328ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170328ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170328ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170328ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170328ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/29/2017 18:15:00', '03/29/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170329ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170329ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170329ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170329ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170329ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170329ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170329ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170329ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/30/2017 18:15:00', '03/30/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170330ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170330ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170330ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170330ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170330ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170330ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170330ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170330ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/31/2017 18:15:00', '03/31/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170331ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170331ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170331ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170331ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170331ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170331ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170331ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170331ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/03/2017 18:15:00', '04/03/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170403ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170403ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170403ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170403ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170403ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170403ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170403ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170403ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/04/2017 18:15:00', '04/04/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170404ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170404ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170404ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170404ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170404ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170404ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170404ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170404ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/05/2017 18:15:00', '04/05/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170405ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170405ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170405ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170405ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170405ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170405ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170405ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170405ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/06/2017 18:15:00', '04/06/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170406ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170406ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170406ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170406ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170406ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170406ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170406ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170406ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/07/2017 18:15:00', '04/07/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170407ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170407ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170407ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170407ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170407ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170407ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170407ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170407ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/10/2017 18:15:00', '04/10/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170410ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170410ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170410ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170410ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170410ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170410ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170410ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170410ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/11/2017 18:15:00', '04/11/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170411ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170411ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170411ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170411ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170411ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170411ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170411ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170411ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/12/2017 18:15:00', '04/12/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170412ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170412ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170412ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170412ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170412ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170412ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170412ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170412ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/13/2017 18:15:00', '04/13/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170413ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170413ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170413ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170413ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170413ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170413ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170413ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170413ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/14/2017 18:15:00', '04/14/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170414ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170414ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170414ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170414ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170414ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170414ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170414ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170414ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/17/2017 18:15:00', '04/17/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170417ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170417ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170417ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170417ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170417ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170417ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170417ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170417ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/18/2017 18:15:00', '04/18/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170418ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170418ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170418ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170418ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170418ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170418ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170418ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170418ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/19/2017 18:15:00', '04/19/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170419ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170419ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170419ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170419ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170419ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170419ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170419ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170419ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/20/2017 18:15:00', '04/20/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170420ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170420ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170420ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170420ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170420ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170420ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170420ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170420ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/21/2017 18:15:00', '04/21/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170421ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170421ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170421ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170421ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170421ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170421ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170421ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170421ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/24/2017 18:15:00', '04/24/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170424ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170424ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170424ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170424ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170424ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170424ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170424ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170424ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/25/2017 18:15:00', '04/25/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170425ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170425ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170425ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170425ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170425ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170425ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170425ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170425ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/26/2017 18:15:00', '04/26/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170426ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170426ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170426ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170426ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170426ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170426ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170426ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170426ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/27/2017 18:15:00', '04/27/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170427ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170427ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170427ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170427ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170427ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170427ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170427ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170427ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/28/2017 18:15:00', '04/28/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170428ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170428ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170428ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170428ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170428ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170428ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170428ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170428ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '05/01/2017 18:15:00', '05/01/2017 19:45:00', 'ALC', 'LTN', 0, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170501ALCLTN9106', 'Regular Fare', 0, 19, 0
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170501ALCLTN9106', 'Regular Fare', 20, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170501ALCLTN9106', 'Regular Fare', 40, 69, 0
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170501ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170501ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170501ALCLTN9106', 'Flexible Fares', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170501ALCLTN9106', 'Staff Travel', 0, 39, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170501ALCLTN9106', 'Internet', 0, 39, 0
EXEC dbo.CreateSector 'ALC', 'LTN', 'Y', 'ALCLTN'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/04/2016 18:15:00', '11/04/2016 19:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161104ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161104ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161104ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161104ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161104ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161104ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/11/2016 18:15:00', '11/11/2016 19:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161111ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161111ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161111ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161111ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161111ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161111ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/18/2016 18:15:00', '11/18/2016 19:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161118ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161118ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161118ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161118ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161118ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161118ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/25/2016 18:15:00', '11/25/2016 19:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161125ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161125ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161125ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161125ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161125ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161125ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/02/2016 18:15:00', '12/02/2016 19:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161202ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161202ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161202ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161202ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161202ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161202ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/09/2016 18:15:00', '12/09/2016 19:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161209ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161209ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161209ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161209ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161209ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161209ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/16/2016 18:15:00', '12/16/2016 19:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161216ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161216ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161216ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161216ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161216ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161216ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/23/2016 18:15:00', '12/23/2016 19:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161223ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161223ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161223ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161223ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161223ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161223ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/30/2016 18:15:00', '12/30/2016 19:45:00', 'ALC', 'LTN', 60, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161230ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161230ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161230ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161230ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161230ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161230ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/06/2017 18:15:00', '01/06/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170106ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170106ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170106ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170106ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170106ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170106ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/13/2017 18:15:00', '01/13/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170113ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170113ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170113ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170113ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170113ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170113ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/20/2017 18:15:00', '01/20/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170120ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170120ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170120ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170120ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170120ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170120ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/27/2017 18:15:00', '01/27/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170127ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170127ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170127ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170127ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170127ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170127ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/03/2017 18:15:00', '02/03/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170203ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170203ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170203ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170203ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170203ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170203ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/10/2017 18:15:00', '02/10/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170210ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170210ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170210ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170210ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170210ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170210ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/17/2017 18:15:00', '02/17/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170217ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170217ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170217ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170217ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170217ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170217ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/24/2017 18:15:00', '02/24/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170224ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170224ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170224ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170224ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170224ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170224ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/03/2017 18:15:00', '03/03/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170303ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170303ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170303ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170303ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170303ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170303ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/10/2017 18:15:00', '03/10/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170310ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170310ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170310ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170310ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170310ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170310ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/17/2017 18:15:00', '03/17/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170317ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170317ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170317ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170317ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170317ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170317ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/24/2017 18:15:00', '03/24/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170324ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170324ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170324ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170324ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170324ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170324ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/31/2017 18:15:00', '03/31/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170331ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170331ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170331ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170331ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170331ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170331ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/07/2017 18:15:00', '04/07/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170407ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170407ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170407ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170407ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170407ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170407ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/14/2017 18:15:00', '04/14/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170414ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170414ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170414ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170414ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170414ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170414ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/21/2017 18:15:00', '04/21/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170421ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170421ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170421ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170421ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170421ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170421ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/28/2017 18:15:00', '04/28/2017 19:45:00', 'ALC', 'LTN', 60, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170428ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170428ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170428ALCLTN9106', 'Regular Fare', 40, 69, 20
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170428ALCLTN9106', 'Regular Fare', 70, 109, 0
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170428ALCLTN9106', 'Regular Fare', 110, 119, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170428ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateSector 'ALC', 'LTN', 'Y', 'ALCLTN'
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/05/2016 18:15:00', '11/05/2016 19:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161105ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161105ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161105ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161105ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161105ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161105ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161105ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161105ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/12/2016 18:15:00', '11/12/2016 19:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161112ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161112ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161112ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161112ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161112ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161112ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161112ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161112ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/19/2016 18:15:00', '11/19/2016 19:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161119ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161119ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161119ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161119ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161119ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161119ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161119ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161119ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '11/26/2016 18:15:00', '11/26/2016 19:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161126ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161126ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161126ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161126ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161126ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161126ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161126ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161126ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/03/2016 18:15:00', '12/03/2016 19:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161203ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161203ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161203ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161203ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161203ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161203ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161203ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161203ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/10/2016 18:15:00', '12/10/2016 19:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161210ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161210ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161210ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161210ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161210ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161210ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161210ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161210ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/17/2016 18:15:00', '12/17/2016 19:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161217ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161217ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161217ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161217ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161217ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161217ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161217ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161217ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/24/2016 18:15:00', '12/24/2016 19:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161224ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161224ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161224ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161224ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161224ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161224ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161224ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161224ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '12/31/2016 18:15:00', '12/31/2016 19:45:00', 'ALC', 'LTN', 120, 'CF', NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20161231ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20161231ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20161231ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20161231ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20161231ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20161231ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20161231ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20161231ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/07/2017 18:15:00', '01/07/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170107ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170107ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170107ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170107ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170107ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170107ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170107ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170107ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/14/2017 18:15:00', '01/14/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170114ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170114ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170114ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170114ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170114ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170114ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170114ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170114ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/21/2017 18:15:00', '01/21/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170121ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170121ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170121ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170121ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170121ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170121ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170121ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170121ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '01/28/2017 18:15:00', '01/28/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170128ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170128ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170128ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170128ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170128ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170128ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170128ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170128ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/04/2017 18:15:00', '02/04/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170204ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170204ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170204ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170204ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170204ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170204ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170204ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170204ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/11/2017 18:15:00', '02/11/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170211ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170211ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170211ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170211ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170211ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170211ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170211ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170211ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/18/2017 18:15:00', '02/18/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170218ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170218ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170218ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170218ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170218ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170218ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170218ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170218ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '02/25/2017 18:15:00', '02/25/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170225ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170225ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170225ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170225ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170225ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170225ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170225ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170225ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/04/2017 18:15:00', '03/04/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170304ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170304ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170304ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170304ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170304ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170304ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170304ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170304ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/11/2017 18:15:00', '03/11/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170311ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170311ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170311ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170311ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170311ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170311ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170311ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170311ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/18/2017 18:15:00', '03/18/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170318ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170318ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170318ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170318ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170318ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170318ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170318ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170318ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '03/25/2017 18:15:00', '03/25/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170325ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170325ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170325ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170325ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170325ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170325ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170325ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170325ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/01/2017 18:15:00', '04/01/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170401ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170401ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170401ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170401ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170401ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170401ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170401ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170401ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/08/2017 18:15:00', '04/08/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170408ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170408ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170408ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170408ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170408ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170408ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170408ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170408ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/15/2017 18:15:00', '04/15/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170415ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170415ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170415ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170415ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170415ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170415ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170415ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170415ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/22/2017 18:15:00', '04/22/2017 19:45:00', 'ALC', 'LTN', 120, NULL, NULL, NULL, 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170422ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170422ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170422ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170422ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170422ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170422ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170422ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170422ALCLTN9106', 'Internet', 60, 79, 0
EXEC dbo.CreateFlightScheduleWithCapacity 'A319', 'EZ', '9106      ', '04/29/2017 18:15:00', '04/29/2017 19:45:00', 'ALC', 'LTN', 120, NULL, 'DTC', 'ATC', 'Y', 120, 120
EXEC dbo.CreateFlightFareWithFlightKey 'T', 'GBP', 20, '20170429ALCLTN9106', 'Regular Fare', 0, 19, 20
EXEC dbo.CreateFlightFareWithFlightKey 'Q', 'GBP', 30, '20170429ALCLTN9106', 'Regular Fare', 20, 39, 20
EXEC dbo.CreateFlightFareWithFlightKey 'L', 'GBP', 40, '20170429ALCLTN9106', 'Regular Fare', 40, 69, 30
EXEC dbo.CreateFlightFareWithFlightKey 'K', 'GBP', 50, '20170429ALCLTN9106', 'Regular Fare', 70, 109, 40
EXEC dbo.CreateFlightFareWithFlightKey 'H', 'GBP', 60, '20170429ALCLTN9106', 'Regular Fare', 110, 119, 10
EXEC dbo.CreateFlightFareWithFlightKey 'M', 'GBP', 100, '20170429ALCLTN9106', 'Flexible Fares', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'P', 'GBP', 5, '20170429ALCLTN9106', 'Staff Travel', 60, 79, 0
EXEC dbo.CreateFlightFareWithFlightKey 'V', 'GBP', 10, '20170429ALCLTN9106', 'Internet', 60, 79, 0

PRINT N'Completed EZ9 operations'
COMMIT TRANSACTION
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
    DECLARE @ErrorMessage nvarchar(max), @ErrorSeverity int, @ErrorState int;
    SELECT @ErrorMessage = ERROR_MESSAGE() + ' Line ' + CAST(ERROR_LINE() as nvarchar(5)), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
END CATCH