/* 
===========================================================
Gamified Travel Management Database System
Sample SQL Queries and Database Objects
===========================================================

This SQL file demonstrates the core database structure for a 
gamified travel tracking platform. The system stores users, 
destinations, completed trips, achievements, and challenges.

It also includes sample queries, views, triggers, functions, 
stored procedures, and indexes used for reporting, performance, 
and gamification logic.
*/


/* =========================================================
1. TABLE CREATION
========================================================= */

/* Users Table
Stores user profile details, total XP, level, join date, 
and friend list information.
*/
CREATE TABLE Users (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    TotalXP INT DEFAULT 0,
    Level INT DEFAULT 1,
    JoinDate DATE NOT NULL,
    FriendsList JSON
);


/* Destinations Table
Stores travel destination details, including category, 
difficulty level, and XP value.
*/
CREATE TABLE Destinations (
    DestinationID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    Difficulty ENUM('Easy', 'Medium', 'Hard') NOT NULL,
    XPValue INT NOT NULL
);


/* Trips Table
Stores completed or planned trips and connects users 
to destinations through foreign keys.
*/
CREATE TABLE Trips (
    TripID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    DestinationID INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    Review TEXT,
    Photos JSON,
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (DestinationID) REFERENCES Destinations(DestinationID)
);


/* Achievements Table
Stores achievement badges and the XP reward attached 
to each achievement.
*/
CREATE TABLE Achievements (
    AchievementID INT AUTO_INCREMENT PRIMARY KEY,
    Title VARCHAR(100) NOT NULL,
    Requirement TEXT NOT NULL,
    BadgeImage VARCHAR(255),
    RewardXP INT NOT NULL
);


/* Challenges Table
Stores time-bound travel challenges that users can join 
to earn additional XP.
*/
CREATE TABLE Challenges (
    ChallengeID INT AUTO_INCREMENT PRIMARY KEY,
    Title VARCHAR(100) NOT NULL,
    RewardXP INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    ParticipantsList JSON,
    Status ENUM('Active', 'Completed') DEFAULT 'Active'
);


/* =========================================================
2. SAMPLE QUERIES
========================================================= */

/* Query 1: Find users with more than 5,000 XP.
This helps identify highly engaged users.
*/
SELECT 
    Name, 
    Email, 
    TotalXP, 
    Level
FROM Users
WHERE TotalXP > 5000;


/* Query 2: Join users, trips, and destinations.
This returns completed trips with user and destination details.
*/
SELECT 
    Users.Name AS UserName,
    Destinations.Name AS Destination,
    Trips.StartDate,
    Trips.EndDate
FROM Trips
JOIN Users 
    ON Trips.UserID = Users.UserID
JOIN Destinations 
    ON Trips.DestinationID = Destinations.DestinationID
WHERE Trips.EndDate <= CURRENT_DATE;


/* Query 3: Insert a new trip record.
This records a completed trip and stores review/photo details.
*/
INSERT INTO Trips (
    UserID, 
    DestinationID, 
    StartDate, 
    EndDate, 
    Review, 
    Photos
)
VALUES (
    1, 
    101, 
    '2024-06-01', 
    '2024-06-15', 
    'Amazing experience!', 
    JSON_ARRAY('photo1.jpg', 'photo2.jpg')
);


/* Query 4: Delete a trip record.
This removes a trip based on TripID.
*/
DELETE FROM Trips
WHERE TripID = 10;


/* =========================================================
3. VIEWS
========================================================= */

/* Leaderboard View
Ranks users based on TotalXP to support gamification.
*/
CREATE VIEW Leaderboard AS
SELECT 
    Name, 
    TotalXP, 
    Level, 
    RANK() OVER (ORDER BY TotalXP DESC) AS UserRank
FROM Users;


/* User Achievements View
Displays user achievement details and reward XP.
Note: This view assumes a UserAchievements table exists.
*/
CREATE VIEW UserAchievementsView AS
SELECT 
    Users.Name,
    Achievements.Title,
    Achievements.RewardXP,
    UserAchievements.DateUnlocked
FROM UserAchievements
JOIN Users 
    ON UserAchievements.UserID = Users.UserID
JOIN Achievements 
    ON UserAchievements.AchievementID = Achievements.AchievementID;


/* =========================================================
4. TRIGGERS, FUNCTIONS, AND STORED PROCEDURES
========================================================= */

/* Trigger: Update user level based on XP.
Automatically updates the user level when TotalXP changes.
*/
CREATE TRIGGER UpdateUserLevel
AFTER UPDATE ON Users
FOR EACH ROW
BEGIN
    IF NEW.TotalXP >= 1000 AND NEW.TotalXP < 3000 THEN
        UPDATE Users 
        SET Level = 2 
        WHERE UserID = NEW.UserID;

    ELSEIF NEW.TotalXP >= 3000 THEN
        UPDATE Users 
        SET Level = 3 
        WHERE UserID = NEW.UserID;
    END IF;
END;


/* Function: Calculate total XP for a user.
Calculates XP earned from completed trips.
*/
CREATE FUNCTION CalculateTotalXP(user_id INT) 
RETURNS INT
BEGIN
    DECLARE total_xp INT;

    SELECT 
        SUM(Destinations.XPValue) 
    INTO total_xp
    FROM Trips
    JOIN Destinations 
        ON Trips.DestinationID = Destinations.DestinationID
    WHERE Trips.UserID = user_id;

    RETURN total_xp;
END;


/* Stored Procedure: Award achievement to a user.
Adds an achievement and increases the user's TotalXP.
Note: This procedure assumes a UserAchievements table exists.
*/
CREATE PROCEDURE AwardAchievement(
    IN user_id INT, 
    IN achievement_id INT
)
BEGIN
    INSERT INTO UserAchievements (
        UserID, 
        AchievementID, 
        DateUnlocked
    )
    VALUES (
        user_id, 
        achievement_id, 
        CURRENT_DATE
    );

    UPDATE Users 
    SET TotalXP = TotalXP + (
        SELECT RewardXP 
        FROM Achievements 
        WHERE AchievementID = achievement_id
    )
    WHERE UserID = user_id;
END;


/* =========================================================
5. PERFORMANCE OPTIMIZATION INDEXES
========================================================= */

/* Speeds up user lookup by email. */
CREATE INDEX idx_users_email 
ON Users(Email);


/* Speeds up joins between Trips and Users. */
CREATE INDEX idx_trips_userid 
ON Trips(UserID);


/* Speeds up filtering destinations by country. */
CREATE INDEX idx_destinations_country 
ON Destinations(Country);


/* Improves leaderboard ranking queries. */
CREATE INDEX idx_users_xp_level 
ON Users(TotalXP, Level);


/* =========================================================
6. PYTHON DATA GENERATION REFERENCE
===========================================================

The project also used Python and the Faker library to generate 
sample test data for database testing.

Generated data included:

- 1,000 users with realistic names, emails, join dates, XP values, 
  and friend lists.
- 500 destinations with city names, countries, categories, 
  difficulty levels, and XP values.

This supported scalability testing and helped validate the database 
design under larger data volumes.

===========================================================
End of File
===========================================================
*/
