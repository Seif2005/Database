--------------------------2.1 A
CREATE DATABASE Telecom_Team_26;
GO
USE Telecom_Team_26;

-- helper functions
GO
CREATE FUNCTION calculate_remaining_balance(@paymentID INT, @planID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @payment_amount DECIMAL(10, 2);
    DECLARE @plan_price DECIMAL(10, 2);
    DECLARE @remaining_balance DECIMAL(10, 2);

    SELECT 
        @payment_amount = p.amount,
        @plan_price = sp.price
    FROM 
        payment p INNER JOIN Service_Plan sp
    ON 
        p.paymentID = @paymentID AND sp.planID = @planID

    SET @remaining_balance = CASE 
        WHEN @payment_amount < @plan_price THEN @plan_price - @payment_amount

        ELSE 0
    END;

    RETURN @remaining_balance;
END;
GO

GO
CREATE FUNCTION Calculate_Extra_Amount(@paymentID INT, @planID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @payment_amount DECIMAL(10, 2);
    DECLARE @plan_price DECIMAL(10, 2);
    DECLARE @Extra_Amount DECIMAL(10, 2);

    SELECT 
        @payment_amount = p.amount,
        @plan_price = sp.price
    FROM 
        payment p INNER JOIN Service_Plan sp
    ON 
        p.paymentID = @paymentID AND sp.planID = @planID

    SET @Extra_Amount = CASE 
        WHEN @payment_amount > @plan_price THEN  @payment_amount- @plan_price 

        ELSE 0
    END;
    RETURN @Extra_Amount;
END;
--------------------------2.1 B
GO
CREATE PROCEDURE createAllTables 
AS
BEGIN
    CREATE TABLE Customer_profile (
    nationalID INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(50),
    address VARCHAR(50),
    date_of_birth DATE
);

CREATE TABLE Customer_Account(
    mobileNo char(11),
    pass varchar(50),
    balance decimal(10,1) DEFAULT 0,
    account_type varchar(50),
    start_date date,
    status varchar(50),
    point int default 0,
    nationalID int,
    PRIMARY KEY (mobileNo),
    CONSTRAINT FK_CustomerAccount_nationalID FOREIGN KEY (nationalID) REFERENCES Customer_profile(nationalID) ON UPDATE CASCADE ON DELETE CASCADE,
    CHECK (status IN ('active','onhold')),
    CHECK (account_type IN ('Post Paid','Prepaid', 'Pay_as_you_go'))
);

CREATE TABLE Service_Plan(
    planID INT IDENTITY (1,1),
    SMS_offered INT,
    minutes_offered INT,
    data_offered INT,
    name Varchar(50),
    price INT, 
    description Varchar(50),
    PRIMARY KEY (planID)
);

CREATE TABLE Subscription(
    mobileNo char(11),
    planID INT,
    subscription_date date,
    status Varchar(50) CHECK (status IN ('active','onhold')),
    PRIMARY KEY(mobileNo,planID),
    CONSTRAINT FK_Subscription_mobileNo FOREIGN KEY (mobileNo) REFERENCES Customer_Account(mobileNo) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_Subscription_planID FOREIGN KEY (planID) REFERENCES Service_Plan(planID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Plan_Usage (
    usageID INT PRIMARY KEY IDENTITY(1,1),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    data_consumption INT DEFAULT 0,
    minutes_used INT DEFAULT 0,
    SMS_sent INT DEFAULT 0,
    mobileNo char(11),
    planID INT,
    CONSTRAINT FK_PlanUsage_mobileNo FOREIGN KEY (mobileNo) REFERENCES Customer_Account(mobileNo) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_PlanUsage_planID FOREIGN KEY (planID) REFERENCES Service_Plan(planID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Payment(
    paymentID INT IDENTITY (1,1), 
    amount DECIMAL (10,1),
    date_of_payment DATE,
    payment_method Varchar(50),
    status Varchar(50),
    mobileNo char(11),
    PRIMARY KEY(paymentID),
    CONSTRAINT FK_Payment_mobileNo FOREIGN KEY (mobileNo) REFERENCES Customer_Account(mobileNo) ON UPDATE CASCADE ON DELETE CASCADE,
    CHECK (payment_method IN ('cash','credit')),
    CHECK (status IN ('successful', 'pending', 'rejected'))
);

CREATE TABLE Process_Payment (
    paymentID INT,
    planID INT,
    remaining_balance AS dbo.calculate_remaining_balance(paymentID , planID),
    extra_amount AS dbo.Calculate_Extra_Amount(paymentID , planID),
    CONSTRAINT FK_ProcessPayment_paymentID FOREIGN KEY (paymentID) REFERENCES Payment(paymentID) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_ProcessPayment_planID FOREIGN KEY (planID) REFERENCES Service_Plan(planID) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY(paymentID)
);

CREATE TABLE Wallet (
    walletID INT PRIMARY KEY IDENTITY(1,1),
    current_balance DECIMAL(10,2) DEFAULT 0,
    currency VARCHAR(50),
    last_modified_date DATE,
    nationalID INT,
    mobileNo char(11),
    CONSTRAINT FK_Wallet_nationalID FOREIGN KEY (nationalID) REFERENCES Customer_profile(nationalID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Transfer_money(
    walletID1 int,
    walletID2 int,
    transfer_id int IDENTITY(1,1),
    amount decimal(10,2),
    transfer_date date,
    PRIMARY KEY (walletID1, walletID2, transfer_id),
    CONSTRAINT FK_TransferMoney_walletID1 FOREIGN KEY (walletID1) REFERENCES Wallet(walletID),
    CONSTRAINT FK_TransferMoney_walletID2 FOREIGN KEY (walletID2) REFERENCES Wallet(walletID)
);

CREATE TABLE Benefits (
    benefitID int PRIMARY KEY IDENTITY(1,1),
    description Varchar(50), 
    validity_date date,
    status Varchar(50),
    CHECK (status IN ('active','expired')),
    mobileNo char(11),
    CONSTRAINT FK_Benefits_mobileNo FOREIGN KEY (mobileNo) REFERENCES Customer_Account(mobileNo) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Points_Group (
    pointID int PRIMARY KEY IDENTITY(1,1), 
    benefitID int,
    pointsAmount int, 
    PaymentID int,
    CONSTRAINT FK_PointsGroup_benefitID FOREIGN KEY (benefitID) REFERENCES Benefits(benefitID) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_PointsGroup_PaymentID FOREIGN KEY (PaymentID) REFERENCES Payment(paymentID)
);

CREATE TABLE Exclusive_Offer(
    offerID int PRIMARY KEY IDENTITY(1,1),
    benefitID int,
    internet_offered int,
    SMS_offered int,
    minutes_offered int,
    CONSTRAINT FK_ExclusiveOffer_benefitID FOREIGN KEY (benefitID) REFERENCES Benefits(benefitID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Cashback(
    CashbackID int IDENTITY(1,1),
    benefitID int,
    walletID int,
    amount int,
    credit_date date,
    PRIMARY KEY (CashbackID, benefitID),
    CONSTRAINT FK_Cashback_benefitID FOREIGN KEY (benefitID) REFERENCES Benefits(benefitID) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_Cashback_walletID FOREIGN KEY (walletID) REFERENCES Wallet(walletID)
);

CREATE TABLE Plan_Provides_Benefits(
    benefitID INT,
    planID INT,
    PRIMARY KEY (benefitID, planID),
    CONSTRAINT FK_PlanProvidesBenefits_benefitID FOREIGN KEY (benefitID) REFERENCES Benefits(benefitID) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_PlanProvidesBenefits_planID FOREIGN KEY (planID) REFERENCES Service_Plan(planID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Shop (
    shopID INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(50),
    category VARCHAR(50)
);

CREATE TABLE Physical_Shop (
    shopID INT PRIMARY KEY,
    address VARCHAR(50),
    working_hours VARCHAR(50),
    CONSTRAINT FK_PhysicalShop_shopID FOREIGN KEY (shopID) REFERENCES Shop(shopID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE E_shop (
    shopID INT PRIMARY KEY,
    URL VARCHAR(50),
    rating INT,
    CONSTRAINT FK_Eshop_shopID FOREIGN KEY (shopID) REFERENCES Shop(shopID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Voucher(
    voucherID int PRIMARY KEY IDENTITY(1,1),
    value int,
    expiry_date date,
    points int,
    mobileNo char(11),
    shopID int,
    redeem_date date,
    CONSTRAINT FK_Voucher_mobileNo FOREIGN KEY (mobileNo) REFERENCES Customer_Account(mobileNo) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_Voucher_shopID FOREIGN KEY (shopID) REFERENCES Shop(shopID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Technical_Support_Ticket(
    ticketID int PRIMARY KEY IDENTITY(1,1),
    mobileNo char(11),
    Issue_description Varchar(50),
    priority_level int,
    status Varchar(50),
    CHECK (status IN ('Open','In Progress', 'Resolved')),
    CONSTRAINT FK_TechnicalSupportTicket_mobileNo FOREIGN KEY (mobileNo) REFERENCES Customer_Account(mobileNo) ON UPDATE CASCADE ON DELETE CASCADE
);


END;
GO
--Creating the tables
Execute  createAllTables

GO

--------------------------2.1 C
CREATE PROCEDURE dropAllTables
AS
BEGIN
ALTER TABLE Customer_Account DROP CONSTRAINT FK_CustomerAccount_nationalID;

ALTER TABLE Subscription DROP CONSTRAINT FK_Subscription_mobileNo;
ALTER TABLE Subscription DROP CONSTRAINT FK_Subscription_planID;

ALTER TABLE Plan_Usage DROP CONSTRAINT FK_PlanUsage_mobileNo;
ALTER TABLE Plan_Usage DROP CONSTRAINT FK_PlanUsage_planID;

ALTER TABLE Payment DROP CONSTRAINT FK_Payment_mobileNo;

ALTER TABLE Process_Payment DROP CONSTRAINT FK_ProcessPayment_paymentID;
ALTER TABLE Process_Payment DROP CONSTRAINT FK_ProcessPayment_planID;

ALTER TABLE Wallet DROP CONSTRAINT FK_Wallet_nationalID;

ALTER TABLE Transfer_money DROP CONSTRAINT FK_TransferMoney_walletID1;
ALTER TABLE Transfer_money DROP CONSTRAINT FK_TransferMoney_walletID2;

ALTER TABLE Benefits DROP CONSTRAINT FK_Benefits_mobileNo;

ALTER TABLE Points_Group DROP CONSTRAINT FK_PointsGroup_benefitID;
ALTER TABLE Points_Group DROP CONSTRAINT FK_PointsGroup_PaymentID;

ALTER TABLE Exclusive_Offer DROP CONSTRAINT FK_ExclusiveOffer_benefitID;

ALTER TABLE Cashback DROP CONSTRAINT FK_Cashback_benefitID;
ALTER TABLE Cashback DROP CONSTRAINT FK_Cashback_walletID;

ALTER TABLE Plan_Provides_Benefits DROP CONSTRAINT FK_PlanProvidesBenefits_benefitID;
ALTER TABLE Plan_Provides_Benefits DROP CONSTRAINT FK_PlanProvidesBenefits_planID;

ALTER TABLE Physical_Shop DROP CONSTRAINT FK_PhysicalShop_shopID;

ALTER TABLE E_shop DROP CONSTRAINT FK_Eshop_shopID;

ALTER TABLE Voucher DROP CONSTRAINT FK_Voucher_mobileNo;
ALTER TABLE Voucher DROP CONSTRAINT FK_Voucher_shopID;

ALTER TABLE Technical_Support_Ticket DROP CONSTRAINT FK_TechnicalSupportTicket_mobileNo;

    DROP TABLE Customer_profile;
    DROP TABLE Customer_Account;
    DROP TABLE Service_Plan;
    DROP TABLE Subscription;
    DROP TABLE Plan_Usage;
    DROP TABLE Payment;
    DROP TABLE Process_Payment;
    DROP TABLE Wallet;
    DROP TABLE Transfer_money;
    DROP TABLE Benefits;
    DROP TABLE Points_Group;
    DROP TABLE Exclusive_Offer;
    DROP TABLE Cashback;
    DROP TABLE Plan_Provides_Benefits;
    DROP TABLE Shop;
    DROP TABLE Physical_Shop;    
    DROP TABLE E_shop;
    DROP TABLE Voucher;
    DROP TABLE Technical_Support_Ticket;
END;

--------------------------2.1 D
GO

CREATE PROCEDURE dropAllProceduresFunctionsViews
AS 
BEGIN 
    --The Functions and Procedures in 2.4
    DROP FUNCTION AccountLoginValidation;
    DROP FUNCTION Consumption;
    DROP PROCEDURE Unsubscribed_Plans;
    DROP FUNCTION Usage_Plan_CurrentMonth;
    DROP FUNCTION Cashback_Wallet_Customer;
    DROP PROCEDURE Ticket_Account_Customer;
    DROP PROCEDURE Account_Highest_Voucher;
    DROP FUNCTION Remaining_plan_amount;
    DROP FUNCTION Extra_plan_amount;
    DROP PROCEDURE Top_Successful_Payments;
    DROP FUNCTION Subscribed_plans_5_Months;
    DROP PROCEDURE Initiate_plan_payment;
    DROP PROCEDURE Payment_wallet_cashback;
    DROP PROCEDURE Initiate_balance_payment;
    DROP PROCEDURE Redeem_voucher_points;
    
    --The Functions and Procedures in 2.3
    DROP PROCEDURE Account_Plan;
    DROP FUNCTION Account_Plan_date;
    DROP FUNCTION Account_Usage_Plan;
    DROP PROCEDURE Benefits_Account;
    DROP FUNCTION Account_SMS_Offers;
    DROP PROCEDURE Account_Payment_Points;
    DROP FUNCTION Wallet_Cashback_Amount;
    DROP FUNCTION Wallet_Transfer_Amount;
    DROP FUNCTION Wallet_MobileNo;
    DROP PROCEDURE Total_Points_Account;

    --The Procedures in 2.1
    DROP PROCEDURE dropAllTables;
    DROP PROCEDURE createAllTables;
    --The Views in 2.2
    DROP VIEW allCustomerAccounts;
    DROP VIEW allServicePlans;
    DROP VIEW allBenefits;
    DROP VIEW AccountPayments;
    DROP VIEW allShops;
    DROP VIEW allResolvedTickets;
    DROP VIEW CustomerWallet;
    DROP VIEW E_shopVouchers;
    DROP VIEW PhysicalStoreVouchers;
    DROP VIEW Num_of_cashback
END;
--------------------------2.1 E
GO
CREATE PROCEDURE clearAllTables
AS
BEGIN 
    DELETE FROM Customer_profile;
	DELETE FROM Customer_Account;
	DELETE FROM Service_Plan;
	DELETE FROM Subscription;
	DELETE FROM Plan_Usage;
	DELETE FROM Payment;
	DELETE FROM Process_Payment;
	DELETE FROM Wallet;
	DELETE FROM Transfer_money;
	DELETE FROM Benefits;
	DELETE FROM Points_Group;
	DELETE FROM Exclusive_Offer;
	DELETE FROM Cashback;
	DELETE FROM Plan_Provides_Benefits;
	DELETE FROM Shop;
	DELETE FROM Physical_Shop;
	DELETE FROM E_shop;
	DELETE FROM Voucher;
	DELETE FROM Technical_Support_Ticket;

END;

--------------------------2.2 A
GO
CREATE VIEW allCustomerAccounts AS 
SELECT ca.mobileNo,
    ca.pass,
    ca.balance,
    ca.account_type,
    ca.start_date,
    ca.status,
    ca.point,
    cp.nationalID,
    cp.first_name,
    cp.last_name,
    cp.email,
    cp.address,
    cp.date_of_birth
FROM Customer_Account AS ca right outer join Customer_profile AS cp 
on (ca.nationalID = cp.nationalID) AND ca.status = 'active';

--------------------------2.2 B
GO
CREATE VIEW allServicePlans AS
SELECT * FROM Service_Plan

--------------------------2.2 C
GO

CREATE VIEW allBenefits AS
SELECT * 
FROM Benefits 
WHERE status = 'active'

--------------------------2.2 D
GO

CREATE VIEW AccountPayments AS 
SELECT 
    p.amount,
    p.date_of_payment,
    p.mobileNo AS 'payment_mobileNo',
    p.payment_method,
    p.paymentID,
    p.status AS 'payment_status',
    c.account_type,
    c.balance,
    c.mobileNo as 'custumer_mobileNo',
    c.nationalID,
    c.pass,
    c.point,
    c.start_date,
    c.status AS 'customer_account_status'
FROM Payment p JOIN Customer_Account c
ON p.mobileNo = c.mobileNo
-------------------------2.2 E
GO

CREATE VIEW allShops AS
SELECT 
    s.shopID,
    s.name,
    s.category,
    ps.address AS physical_address,
    ps.working_hours,
    es.URL AS e_shop_url,
    es.rating AS e_shop_rating
FROM 
    Shop s
LEFT JOIN 
    Physical_Shop ps ON s.shopID = ps.shopID
LEFT JOIN 
    E_Shop es ON s.shopID = es.shopID;
--------------------------2.2 F
GO

CREATE VIEW allResolvedTickets
AS
SELECT * 
FROM Technical_Support_Ticket
WHERE status='Resolved'

--------------------------2.2 G
GO

CREATE VIEW CustomerWallet
AS
SELECT w.walletID ,w.current_balance ,w.currency ,w.last_modified_date ,w.nationalID ,c.first_name ,c.last_name
FROM Wallet w inner join Customer_profile c
on w.nationalID= c.nationalID

--------------------------2.2 H
GO

CREATE VIEW E_shopVouchers AS
SELECT e.shopID , e.URL , e.rating, v.voucherID , v.value 
FROM E_shop e inner join Shop s on e.shopID = s.shopID left outer join Voucher v 
on (s.shopID = v.shopID AND v.redeem_date IS NOT NULL);

--------------------------2.2 I
GO

CREATE VIEW PhysicalStoreVouchers AS
SELECT PS.shopID, PS.address, PS.working_hours,V.voucherID, V.value
FROM Shop S inner join  Physical_Shop PS on (s.shopID = PS.shopID) left outer join Voucher V 
on (V.shopID = PS.shopID AND V.redeem_date IS NOT NULL)
--------------------------2.2 J
GO

CREATE VIEW Num_of_cashback
AS
SELECT C.walletID,count(C.CashbackID) as Num_of_cashback 
FROM Cashback C 
GROUP BY  C.walletID


--------------------------2.3 A
GO

CREATE PROCEDURE Account_Plan
AS 
BEGIN
    SELECT a.mobileNo, s.planID
    FROM Customer_Account a
    INNER JOIN Subscription sub
    ON (a.mobileNo = sub.mobileNo)
    INNER JOIN Service_Plan s
    ON s.planID = sub.planID
END;
--------------------------2.3 B

GO

CREATE FUNCTION Account_Plan_date (@Subscription_Date date , @Plan_id int)
RETURNS TABLE
AS
RETURN (
    SELECT su.mobileNo ,se.planID ,se.name 
    FROM Service_Plan se INNER JOIN Subscription su 
    on se.planID = su.planID
    WHERE se.planID = @Plan_id AND su.subscription_date = @Subscription_Date
);
--------------------------2.3 C
GO

CREATE FUNCTION Account_Usage_Plan(@MobileNo char(11), @from_date date)
RETURNS TABLE
AS
RETURN(
    SELECT 
    p.planID , 
    sum(p.data_consumption ) AS Total_Data_Consumption ,
    sum(minutes_used ) AS Total_Minutes_Used,
    sum(SMS_sent) AS Total_SMS_Sent
    FROM Plan_Usage p
    WHERE p.mobileNo=@MobileNo AND p.start_date>=@from_date
    GROUP by p.planID
)

--------------------------2.3 D
GO 

CREATE PROCEDURE Benefits_Account
@mobile char(11),
@planid int 
AS
BEGIN
    DELETE FROM Benefits
    WHERE benefitID IN(
    SELECT b1.benefitID 
    FROM Benefits b1
    INNER JOIN Plan_Provides_Benefits pb 
    ON pb.benefitID = b1.benefitID
    WHERE b1.mobileNo = @mobile AND pb.planID = @planid
    )
END;
--------------------------2.3 E
GO

CREATE FUNCTION Account_SMS_Offers (@MobileNo char(11))
RETURNS TABLE 
AS 
RETURN (
SELECT EO.offerID , EO.SMS_offered
FROM Exclusive_Offer EO INNER JOIN Benefits B ON (EO.benefitID = B.benefitID)
WHERE B.mobileNo = @MobileNo AND EO.SMS_offered>0
);
--------------------------2.3 F

GO
CREATE PROCEDURE Account_Payment_Points (
@MobileNo char(11))
AS 
BEGIN
    DECLARE @startDate DATE = DATEADD(YEAR, -1, CURRENT_TIMESTAMP)
    SELECT COUNT(p.paymentID) AS Total_Number_of_transactions , SUM(c.point) AS Total_Amount_of_points
    FROM Payment p INNER JOIN Customer_Account c on p.mobileNo=c.mobileNo 
    WHERE 
    p.mobileNo=@MobileNo AND
    p.status='successful' AND 
    p.date_of_payment>=@startDate
END
--------------------------2.3 G
GO

CREATE FUNCTION Wallet_Cashback_Amount (@WalletId INT, @planId INT)
RETURNS INT
AS
BEGIN
    DECLARE @CashbackAmount INT;
    SELECT @CashbackAmount = SUM(c.amount)
    FROM Cashback c INNER JOIN Plan_Provides_Benefits p
    ON (c.benefitID = p.benefitID)
    WHERE c.walletID = @WalletId AND p.planID = @planId;
    RETURN @CashbackAmount;
END;

--------------------------2.3 H
GO

CREATE FUNCTION Wallet_Transfer_Amount (
    @Wallet_id INT,
    @start_date DATE,
    @end_date DATE
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Avg DECIMAL(10,2);

    SELECT @Avg = AVG(t.amount)
    FROM Transfer_money t
    WHERE t.walletID1 = @Wallet_id AND t.transfer_date>=@start_date AND t.transfer_date<=@end_date;

    RETURN @Avg;
END;
--------------------------2.3 I
GO

CREATE FUNCTION Wallet_MobileNo
    (@MobileNo CHAR(11))
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT;
    IF EXISTS (
        SELECT w.mobileNo
        FROM Wallet w
        WHERE w.mobileNo = @MobileNo
    )
    BEGIN
        SET @Result = 1;
    END
    ELSE
    BEGIN
        SET @Result = 0;
    END

    RETURN @Result;
END;
--------------------------2.3 J
GO

CREATE PROCEDURE Total_Points_Account
    @MobileNo CHAR(11),
    @TotalPoints INT OUTPUT
AS
BEGIN
    SELECT @TotalPoints = SUM(pointsAmount)
    FROM Points_Group pg
    JOIN Payment p ON pg.PaymentID = p.paymentID
    WHERE p.mobileNo = @MobileNo;

    UPDATE Customer_Account
    SET point = @TotalPoints
    WHERE mobileNo = @MobileNo;
END;
--------------------------2.4 A
GO

CREATE FUNCTION AccountLoginValidation
 (@MobileNo char(11) , @password varchar(50))
 RETURNS BIT
 AS 
 BEGIN
 DECLARE @Success BIT
    IF EXISTS  (SELECT * FROM  Customer_Account c
                WHERE c.mobileNo = @MobileNo AND  c.pass = @password)
                SET @Success = 1
    ELSE 
                SET @Success = 0
 RETURN @Success
 END
--------------------------2.4 B
GO

CREATE FUNCTION Consumption (@Plan_name varchar(50), @start_date date, @end_date date)
RETURNS TABLE
 AS 
 RETURN ( 
    SELECT sum(pu.data_consumption) AS Data_consumption , sum(pu.minutes_used) AS Minutes_used, sum(pu.SMS_sent) AS SMS_sent
    FROM  Service_Plan sp join Plan_Usage pu on pu.planID=sp.planID
    where sp.name=@Plan_name AND pu.start_date>= @start_date AND pu.end_date<=@end_date       
 )
--------------------------2.4 C
GO

CREATE PROCEDURE Unsubscribed_Plans
@MobileNo char(11)
AS
BEGIN 
    select *
    FROM Service_Plan sp
    where sp.planID  NOT IN (
    select sp.planID
    from Subscription s
    where s.mobileNo = @MobileNo
    )
END;
--------------------------2.4 D
GO 

CREATE FUNCTION Usage_Plan_CurrentMonth(@MobileNo char(11))
RETURNS TABLE
AS
RETURN (
    SELECT P.data_consumption AS 'Data consumption', P.minutes_used AS 'Minutes used', P.SMS_sent AS 'SMS sent'
    FROM Subscription s  
    INNER JOIN Plan_Usage P 
    ON s.mobileNo = p.mobileNo
    WHERE 
    P.mobileNo=@MobileNo AND 
    s.status = 'active' AND 
    p.start_date <= CURRENT_TIMESTAMP AND  
    (p.end_date >= CURRENT_TIMESTAMP OR 
    ( MONTH (p.end_date)=MONTH(CURRENT_TIMESTAMP) AND YEAR (p.end_date)=YEAR(CURRENT_TIMESTAMP) ))
 )
--------------------------2.4 E
GO

CREATE FUNCTION Cashback_Wallet_Customer (@NationalID int)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        c.amount,
        c.benefitID,
        c.CashbackID,
        c.credit_date,
        c.walletID AS 'Cashback_walletId',
        w.currency,
        w.current_balance,
        w.last_modified_date,
        w.mobileNo,
        w.nationalID,
        w.walletID
    FROM Cashback c
    INNER JOIN Wallet w
    ON c.walletID = w.walletID
    WHERE w.nationalID = @NationalID
);
--------------------------2.4 F
GO

 CREATE PROCEDURE Ticket_Account_Customer
 @nationalID INT,
 @T_No INT OUTPUT
 AS
    SELECT @T_No = COUNT(T.ticketID)  
    FROM Customer_Account C INNER JOIN Technical_Support_Ticket T ON (C.mobileNo = T.mobileNo)
    WHERE C.nationalID = @nationalID AND T.status <> 'RESOLVED'

--------------------------2.4 G
GO
 CREATE PROCEDURE Account_Highest_Voucher 
    @MobileNo CHAR(11),
    @Voucher_id INT OUTPUT
AS
BEGIN
    SELECT TOP 1 @Voucher_id = voucherID
    FROM Voucher v
    WHERE v.mobileNo = @MobileNo
    ORDER BY v.value DESC;
END;
--------------------------2.4 H
GO

CREATE FUNCTION Remaining_plan_amount (
    @MobileNo char(11), @plan_name varchar(50)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Remaining DECIMAL(10,2);

    SELECT @Remaining = pp.remaining_balance
    FROM Process_Payment pp
    INNER JOIN Payment p 
    ON p.paymentID = pp.paymentID
    INNER JOIN Service_Plan sp 
    ON sp.planID = pp.planID
    WHERE sp.name = @plan_name AND p.mobileNo = @MobileNo;
    RETURN @Remaining;
END;
--------------------------2.4 I
GO

CREATE FUNCTION Extra_plan_amount
(
    @MobileNo CHAR(11),
    @PlanName VARCHAR(50)
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @ExtraAmount DECIMAL(10, 2);
    SELECT @ExtraAmount = pp.extra_amount
    FROM Process_Payment pp
    JOIN Service_Plan sp ON pp.planID = sp.planID
    JOIN Subscription s ON s.planID = pp.planID
    WHERE sp.name = @PlanName AND s.mobileNo = @MobileNo;
    RETURN @ExtraAmount;
END;
--------------------------2.4 J
GO

CREATE PROCEDURE Top_Successful_Payments
(@MobileNo char(11))
AS 
BEGIN
    SELECT TOP 10 p.*
    FROM Payment p 
    where p.mobileNo=@MobileNo AND
    p.status ='successful'
    ORDER BY p.amount
END;
--------------------------2.4 K
GO
CREATE FUNCTION Subscribed_plans_5_Months (@MobileNo CHAR(11))
RETURNS TABLE
AS
RETURN
(
    SELECT sp.planID, sp.name, sp.SMS_offered, sp.minutes_offered, sp.data_offered, sp.price, sp.description
    FROM Subscription s
    INNER JOIN Service_Plan sp ON s.planID = sp.planID
    WHERE s.mobileNo = @MobileNo
    AND s.subscription_date >= DATEADD(MONTH, -5, GETDATE())
);
GO
--------------------------2.4 L
GO
CREATE FUNCTION GetPaymentID(@time date)
RETURNS INT
AS
BEGIN
    DECLARE @p_id INT;
    SELECT @p_id = p.paymentID
    FROM Payment p
    WHERE p.date_of_payment = @time;
    RETURN @p_id;

END;
GO
CREATE PROCEDURE Initiate_plan_payment 
    @MobileNo CHAR(11),
    @amount DECIMAL(10, 1),
    @payment_method VARCHAR(50),
    @plan_id INT
    AS
    BEGIN
       DECLARE @time datetime;
       
       SET @time = CURRENT_TIMESTAMP;

       INSERT INTO  Payment(amount ,date_of_payment ,payment_method ,status , mobileNo )
       VALUES(@amount,@time,@payment_method,'successful',@MobileNo)

       UPDATE Subscription 
       SET subscription_date = @time , status='active'
       WHERE mobileNo= @MobileNo

       

       INSERT INTO Plan_Usage (start_date, end_date, mobileNo, planID)
       VALUES(@time,DATEADD(MONTH,1,@time),@MobileNo,@Plan_id)
       --call the new stored Procedures
       DECLARE @rem_balance DECIMAL(10,2);
       DECLARE @extra_am DECIMAL(10,2);
       DECLARE @payment_ID INT;
       SET @payment_ID = dbo.GetPaymentID(@time);
       INSERT INTO Process_Payment VALUES (@payment_ID,@plan_id);
    END

go


--------------------------2.4 M
CREATE PROCEDURE Payment_wallet_cashback (
    @MobileNo CHAR(11),
    @Payment_id INT,
    @Benefit_id INT
)
AS
BEGIN
    DECLARE @CashbackAmount DECIMAL(10,2);
    DECLARE @WalletID INT;

    SELECT @CashbackAmount = 0.1 * amount 
    FROM Payment
    WHERE paymentID = @Payment_id AND mobileNo = @MobileNo;

    SELECT @WalletID = walletID 
    FROM Wallet 
    WHERE mobileNo = @MobileNo;

    UPDATE Wallet
    SET current_balance = current_balance + @CashbackAmount
    WHERE walletID = @WalletID;

    INSERT INTO Cashback (benefitID, walletID, amount, credit_date)
    VALUES (@Benefit_id, @WalletID, @CashbackAmount, CURRENT_TIMESTAMP);
END;
GO
--------------------------2.4 N
CREATE PROCEDURE Initiate_balance_payment
    @MobileNo CHAR(11),
    @Amount DECIMAL(10,1),
    @PaymentMethod VARCHAR(50)
    AS
    BEGIN
    DECLARE @currentBalance DECIMAL(10,1);

    SELECT @currentBalance = balance FROM Customer_Account WHERE mobileNo = @MobileNo;

    INSERT INTO Payment (amount, date_of_payment, payment_method, status, mobileNo)
    VALUES (@Amount, CURRENT_TIMESTAMP, @PaymentMethod, 'successful', @MobileNo);

    UPDATE Customer_Account
    SET balance = balance + @Amount
    WHERE mobileNo = @MobileNo;

    END;
--------------------------2.4 O
GO
    CREATE PROCEDURE Redeem_voucher_points
    @MobileNo CHAR(11),
    @VoucherID INT
    AS
    BEGIN
    IF EXISTS (
        SELECT *
        FROM Voucher
        WHERE voucherID = @VoucherID
          AND mobileNo = @MobileNo
          AND redeem_date IS NULL
    )
    BEGIN
        DECLARE @VoucherPoints INT;

        SELECT @VoucherPoints = points FROM Voucher WHERE voucherID = @VoucherID AND redeem_date IS NULL;

        UPDATE Customer_Account
        SET point = point + @VoucherPoints
        WHERE mobileNo = @MobileNo;

        UPDATE Voucher
        SET redeem_date = CURRENT_TIMESTAMP
        WHERE voucherID = @VoucherID;
    END
    END;

GO


--Test
--use model;
--DROP DATABASE Telecom_Team_26