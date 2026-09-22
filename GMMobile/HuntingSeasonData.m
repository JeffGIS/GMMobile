//
//  HuntingSeasonData.m
//  NVMobile
//
//  Created by Jeff Smith on 10/6/25.
//  Copyright © 2025 GSSi. All rights reserved.
//
extern long currentGMTOff;
extern int currentIsDST;

#import "HuntingSeasonData.h"

@implementation HuntingSeasonData

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.nonBackedUpFilePath;
        _path = [NSBundle.mainBundle pathForResource:@"areapoly"
                                              ofType:@"slt"];
        int fileSize = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                              error:nil].fileSize;
        NSLog(@"Season Database init");
    }
    self.label = [NSString stringWithFormat:@"MN Grouse"];
    self.CurrentSpecies = Grouse;
    return self;
}

- (void)dealloc
{
    [self close:TRUE];
    NSLog(@"Season Database dealloc");
}

- (BOOL)open
{
    BOOL rtn = FALSE;
    if (!_isOpen)
    {
        _isOpen = !SQLOK(__FILE__,__LINE__,SQLite_Open(_path.UTF8String, &_database), _database);
        NSLog(@"Season Database open");
        
        if (_isOpen)
            rtn = TRUE;
    }
    return rtn;
}

- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
        SQLOK(__FILE__,__LINE__,SQLite_Close(&_database),_database);
        NSLog(@"Boundary Database close");
        _isOpen = NO;
    }
}

- (void)clear
{
    [self close:TRUE];
    
}

- (int) datasetVersion
{
    int rtn = -1;
    BOOL opened = [self open];
    if (_isOpen && _fileSize > 0)
    {
        NSString *query = [NSString stringWithFormat:@"SELECT VersionNum FROM HUNTING_SEASONS"];
        
        sqlite3_stmt *statement = NULL;
        
        BOOL st = SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);;
        if (st)
        {
            
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                LPSTR version = (LPSTR)sqlite3_column_text(statement, 0);
                
                if (version)
                    rtn = atoi(version);
            }
            
            SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
        }
    }
    [self close:opened];
    return rtn;
}

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOK(__FILE__,__LINE__,SQLiteExec(_database, cmd, 0, 0, 0), _database);
    return rtn;
}

- (void)startTransaction
{
    [self open];
    SQLOK(__FILE__,__LINE__,SQLiteExec(_database, "BEGIN", 0, 0, 0), _database);
}

- (void)commitTransaction
{
    SQLOK(__FILE__,__LINE__,SQLiteExec(_database, "COMMIT", 0, 0, 0),_database);
}

- (void) updateInfo:(WeatherRecord *)weatherData
{
    //if (weatherData.)
    struct tm startDate;
    struct tm endDate;
    int sunRiseOffset = 30 * 60;
    
    startDate.tm_sec=0;        /* seconds after the minute [0-60] */
    startDate.tm_min=0;        /* minutes after the hour [0-59] */
    startDate.tm_hour=0;    /* hours since midnight [0-23] */
    startDate.tm_mday=19;    /* day of the month [1-31] */
    startDate.tm_mon=8;        /* months since January [0-11] */
    startDate.tm_year=126;    /* years since 1900 */
    startDate.tm_wday;    /* days since Sunday [0-6] */
    startDate.tm_yday;    /* days since January 1 [0-365] */
    startDate.tm_isdst=currentIsDST;    /* Daylight Savings Time flag */
    startDate.tm_gmtoff=currentGMTOff;    /* offset from UTC in seconds */
    char    *_LIBC_CSTR    tm_zone=0;    /* timezone abbreviation */
    _startHuntingDate = mktime (&startDate);
    NSString * date = [WeatherData forecastDayandTime:_startHuntingDate];
    endDate = startDate;
    endDate.tm_hour = 24;
    endDate.tm_min = 59;
    endDate.tm_mon = 0;
    endDate.tm_mday = 3;
    endDate.tm_year++;
    _endHuntingDate = mktime (&endDate);
    int secondsPerHour = 60 * 60;
    int oneDay = 24 * secondsPerHour;
    long currentTime = NSDate.date.timeIntervalSince1970;
    //currentTime -= secondsPerHour*14;
    _isOpen = FALSE;
    
    if (currentTime > _startHuntingDate && currentTime < _endHuntingDate)
    {
        _startHuntingTime = weatherData.sunRise-sunRiseOffset;
        _endHuntingTime = weatherData.sunSet;
        long timeSinceStartTime = currentTime - _startHuntingTime;
        if (currentTime >= _startHuntingTime && currentTime < _endHuntingTime)
        {
            _isOpen = TRUE;
            int hours = (_endHuntingTime-currentTime) / secondsPerHour;
            int minutes = ((_endHuntingTime-currentTime) - (hours * secondsPerHour)) / 60;
            NSString * closeTime = [WeatherData forecastDayandTime:_endHuntingTime];
            closeTime = textAfter(closeTime,@" ");
            if (hours > 0)
                _line1 = [NSString stringWithFormat:@"%i hrs and %i min",hours,minutes];
            else
                _line1 = [NSString stringWithFormat:@"%i minutes",minutes];

            _line2 = [NSString stringWithFormat:@"until closes at %@",closeTime];
        }
        else if (currentTime < _startHuntingTime)
        {
            int hours = (_startHuntingTime-currentTime) / secondsPerHour;
            int minutes = ((_startHuntingTime-currentTime) - (hours * secondsPerHour)) / 60;
            NSString * openTime = [WeatherData forecastDayandTime:_startHuntingTime];
            openTime = textAfter(openTime,@" ");
            if (hours > 0)
                _line1 = [NSString stringWithFormat:@"%i hrs and %i min",hours,minutes];
            else
                _line1 = [NSString stringWithFormat:@"%i minutes",minutes];

            _line2 = [NSString stringWithFormat:@"until opens at %@",openTime];
        }
        else
        {
            _startHuntingTime = currentTime + oneDay - timeSinceStartTime;
            int hours = (_startHuntingTime-currentTime) / secondsPerHour;
            int minutes = ((_startHuntingTime-currentTime) - (hours * secondsPerHour)) / 60;
            NSString * openTime = [WeatherData forecastDayandTime:_startHuntingTime];
            openTime = textAfter(openTime,@" ");
            if (hours > 0)
                _line1 = [NSString stringWithFormat:@"%i hrs and %i min",hours,minutes];
            else
                _line1 = [NSString stringWithFormat:@"%i minutes",minutes];

            _line2 = [NSString stringWithFormat:@"until opens at %@",openTime];
        }
    }
    else
    {
        _isOpen = FALSE;
        int hours = (_endHuntingTime-currentTime) / secondsPerHour;
        int minutes = ((_endHuntingTime-currentTime) - (hours * secondsPerHour)) / 60;
        NSString * closeTime = [WeatherData forecastDayandTime:_endHuntingTime];
        closeTime = textAfter(closeTime,@"Today ");
        if (hours > 0)
            _line1 = [NSString stringWithFormat:@"%i hrs and %i min",hours,minutes];
        else
            _line1 = [NSString stringWithFormat:@"%i minutes",minutes];

        _line2 = [NSString stringWithFormat:@"until close at %@",closeTime];
    }
    NSString * sunRise = [WeatherData forecastDayandTime:weatherData.sunRise-sunRiseOffset];
    NSString * sunSet = [WeatherData forecastDayandTime:weatherData.sunSet];

    NSString * riseText = textAfter(sunRise,@"Today ");
    NSString * setText = textAfter(sunSet, @"Today ");
    NSString * sinceUntilText = [self getSinceUntilText:weatherData.sunRise
                                               setText:weatherData.sunSet];
    _label = @"MN Grouse";
    /*_sunRiseSetLabel.font =[UIFont systemFontOfSize: 22];
    if (_huntingSeasonData.CurrentSpecies == Grouse)
    {
        _sunRiseTitleLabel.backgroundColor = UIColor.blackColor;
        _sunRiseTitleLabel.numberOfLines = 1;
        if (_huntingSeasonData.isOpen)
        {
            _sunRiseTitleLabel.textColor = UIColor.greenColor;
        }
        else
        {
            _sunRiseSetLabel.text = [NSString stringWithFormat:@"%@\nopens at %@",sinceUntilText,riseText];
            _sunRiseTitleLabel.textColor = UIColor.redColor;
        }
*/
    //date = [WeatherData forecastDayandTime:_endHuntingDate];
    ii = 1;
    return;
}

- (void)setLabel:(UILabel *)label
{
    
}
- (NSString*) getSinceUntilText:(time_t)riseTime
                        setText:(time_t)setTime
{
    NSString * rtn = @"";
    time_t now = NSDate.date.timeIntervalSince1970;
    long riseDiff = now - riseTime;
    long setDiff = setTime - now;
    NSString * sinceUntil = @"since";
    if (riseDiff < 0)
    {
        if (riseDiff < 0)
            sinceUntil = @"until";
        riseDiff = abs (riseDiff) / 60;
        int mins = riseDiff % 60;
        int hours = riseDiff / 60;
        if (hours)
        {
            NSString * hourText = @"hr";
            if (hours > 1)
                hourText = @"hrs";
            if (mins)
                rtn = [NSString stringWithFormat:@"%i %@ %i min %@",hours,hourText, mins,sinceUntil];
            else
                rtn = [NSString stringWithFormat:@"%i %@ %@",hours,hourText,sinceUntil];
        }
        else
        {
            rtn = [NSString stringWithFormat:@"%i minutes %@",mins,sinceUntil];
        }
    }
    else
    {
        if (setDiff > 0)
            sinceUntil = @"until";
        setDiff = abs (setDiff) / 60;
        int mins = setDiff % 60;
        int hours = setDiff / 60;
        if (hours)
        {
            NSString * hourText = @"hr";
            if (hours > 1)
                hourText = @"hrs";
            if (mins)
                rtn = [NSString stringWithFormat:@"%i %@ %i min %@",hours,hourText, mins,sinceUntil];
            else
                rtn = [NSString stringWithFormat:@"%i %@ %@",hours,hourText,sinceUntil];
        }
        else
        {
            rtn = [NSString stringWithFormat:@"%i minutes %@",mins,sinceUntil];
        }
    }
    return rtn;
}

- (NSMutableArray *)getSeasonTypes
{
    NSMutableArray *types = NSMutableArray.new;
    
    return types;
}
- (NSMutableArray *)getSeasonDataForType:(NSString *)type
{
    NSMutableArray *seasonData = NSMutableArray.new;
    
    return seasonData;
}


@end
