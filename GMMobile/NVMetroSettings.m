//
//  NVMetroSettings.m
//  NVMobile
//
//  Created by Jeff Smith on 12/23/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import "NVMetroSettings.h"

static int currentTextValues[CPFeaturesCount]={0};
static int nParcelTypesWanted=-1;
static int parcelsWanted[CPFeaturesCount];

@implementation NVMetroTextOptions
-(NSString *) description
{
    NSString * rtn = textBefore(_desc,@"\x03");
    return rtn;
}
-(NSString *)fields
{
    if (_numTextFields < 0)
    {
        return @"";
    }
    else
        return _fields;
}
@end

CORNERPOINTS CornerPointsFromRegion (GMSVisibleRegion region)
{
    CORNERPOINTS _latlonCornerPoints;
    _latlonCornerPoints.nearLeft.x = region.nearLeft.longitude;
    _latlonCornerPoints.nearLeft.y = region.nearLeft.latitude;
    _latlonCornerPoints.farLeft.x = region.farLeft.longitude;
    _latlonCornerPoints.farLeft.y = region.farLeft.latitude;
    _latlonCornerPoints.farRight.x = region.farRight.longitude;
    _latlonCornerPoints.farRight.y = region.farRight.latitude;
    _latlonCornerPoints.nearRight.x = region.nearRight.longitude;
    _latlonCornerPoints.nearRight.y = region.nearRight.latitude;
    return _latlonCornerPoints;
}


@implementation NVMetroSettings

+ (NVMetroSettings *)sharedInstance
{
    static NVMetroSettings *sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,
                  ^{
                      sharedInstance = [[NVMetroSettings alloc] init];
                  });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.currentAdjustmentValue = CPAdjustCountPerSQMile;
        _currentValues = NSMutableArray.new;
        for (CPFeatures i = 0;i<CPFeaturesCount;i++)
        {
            NSMutableArray * values = NSMutableArray.new;
            [_currentValues addObject:values];
            self.currentFeature = i;
            if (i == CPFLandUse)
                [self setCurrentValue:1];
            else
                [self setCurrentValue:0];
        }
        self.currentFeature = CPFTracts;
        [self setCurrentValue:1];
//        currentValues[self.currentFeature] = self.currentFeatureValue = 1;
    }
    
    return self;
}

- (void) setOverUnder:(BOOL)overUnder
{
    _overUnder = overUnder;
}
-(void) setCurrentFeature:(CPFeatures)currentFeature
{
    _currentFeature = currentFeature;
    self.currentFeatureValue = _currentValues[currentFeature];
    [self currentTextSelection:currentTextValues[currentFeature]];
    switch (_currentFeature)
    {
        default:
        case CPFParcels:
            nParcelTypesWanted = -1;
            break;
        case CPFParcels_COM:
            nParcelTypesWanted = 3;
            parcelsWanted[0]=120;
            parcelsWanted[1]=130;
            parcelsWanted[2]=143;
            break;
        case CPFParcels_RES:
            nParcelTypesWanted = 5;
            parcelsWanted[0]=111;
            parcelsWanted[1]=112;
            parcelsWanted[2]=113;
            parcelsWanted[3]=114;
            parcelsWanted[4]=115;
            break;
        case CPFParcels_AG:
            nParcelTypesWanted = 1;
            parcelsWanted[0]=100;
            break;
        case CPFParcels_IND:
            nParcelTypesWanted = 2;
            parcelsWanted[0]=142;
            parcelsWanted[1]=151;
            break;
    }
}

-(void) setCurrentFeatureValue:(NSArray *)currentFeatureValue
{
    _currentFeatureValue = currentFeatureValue;
}
- (NSArray*) getCurrentFeatureValue
{
    int ii = 1;
    return _currentFeatureValue;
}
-(BOOL) wantUseCode:(int)code
{
    if (nParcelTypesWanted < 1)
        return TRUE;
    for (int i=0;i<nParcelTypesWanted;i++)
    {
        if (code == parcelsWanted[i])
            return TRUE;
    }
    return FALSE;
}
- (NSString *) currentFeatureText
{
    NSString * rtn = stringWithoutID([self features][_currentFeature]);
    return rtn;
}

- (int) valueID:(NSString*)value
{
    NSString * IDStr = textAfter (value,@"\x04");
    int ID = (int)IDStr.integerValue;
    return ID;
}
- (NSString *) currentValueText
{
    NSArray * values = _currentValues[_currentFeature];
    NSString * rtn = @"";
    int lastID = -1;
    int toPos = -1;
    for (NSString *str in values)
    {
        int ID = [self valueID:str];
        NSString *str2 = stringWithoutID(str);
        if (ID - lastID == 1 && toPos != -1)
        {
            NSRange range = [str2 rangeOfString:@" to "];
            
            if (range.location != NSNotFound)
            {
                NSString * toVal = [str2 substringFromIndex:(range.location + 4)];
                rtn = [rtn substringToIndex:toPos];
                rtn = [rtn stringByAppendingString:toVal];
            }
            
        }
        else
        {
            if (rtn.length)
                rtn = [rtn stringByAppendingString:@" "];
            rtn = [rtn stringByAppendingString:str2];
            NSRange range = [rtn rangeOfString:@" to " options:NSBackwardsSearch];
            if (range.location != NSNotFound)
                 toPos = (int)range.location + 4;
        }
        lastID = ID;
    }
    return rtn;
}
- (NSString *) currentTextText
{
    NSString * rtn = self.currentTextOption.description;
    return rtn;
}
- (NSString *) currentAdjustmentText
{
    NSArray * values = [self adjustmentOptions];
    NSString * rtn = stringWithoutID(values[_currentAdjustmentValue]);
    return rtn;
}
- (NSString *) currentValueFields
{
    NSArray * values = _currentValues[_currentFeature];
    NSString * rtn = @"";
    for (NSString * value in values)
    {
        NSString * str = textAfter(value, @"\x03");
        str = textBefore (str,@"\x04");
        str = textBefore (str,@"\x05");
        if (rtn.length)
            rtn = [rtn stringByAppendingString:@","];
        rtn = [rtn stringByAppendingString:str];
    }
    return rtn;
}
- (NSString *) currentValueField:(int)index
{
    NSArray * values = [self valuesForFeature:_currentFeature];
    NSString * rtn = textAfter(values[index], @"\x03");
    rtn = textBefore (rtn,@"\x04");
    rtn = textBefore (rtn,@"\x05");
    return rtn;
}
- (void) setCurrentValue:(NSInteger)value
{
    NSArray * values = [self valuesForFeature:_currentFeature];
    NSMutableArray *curValues = NSMutableArray.new;
    if (values)
        [curValues addObject:values[value]];
    [_currentValues replaceObjectAtIndex:_currentFeature withObject:curValues];
}
- (NSMutableArray*) currentValues
{
    return _currentValues;
}
- (void) updateCurrentValues:(NSArray*)values
{
    [_currentValues replaceObjectAtIndex:_currentFeature withObject:values];
    //currentValues[_currentFeature] = (int)value;
    //self.currentFeatureValue = (int)value;
}

- (NSArray *) features
{
    NSMutableArray * rtn = NSMutableArray.new;
    
    for (int feature = 0;feature<CPFeaturesCount;feature++)
    {
        switch (feature)
        {
            case CPFParcels:
                [rtn addObject:stringWithID("Parcels",feature)];
                break;
            case CPFParcels_RES:
                [rtn addObject:stringWithID("Parcels - Residential Only",feature)];
                break;
            case CPFParcels_COM:
                [rtn addObject:stringWithID("Parcels - Commercial Only",feature)];
                break;
            case CPFParcels_IND:
                [rtn addObject:stringWithID("Parcels - Industrial Only",feature)];
                break;
            case CPFParcels_AG:
                [rtn addObject:stringWithID("Parcels - Agricultural Only",feature)];
                break;
            case CPFLandUse:
                [rtn addObject:stringWithID("Land Use",feature)];
                break;
            case CPFBlocks:
                [rtn addObject:stringWithID("Census Blocks",feature)];
                break;
            case CPFBlockGroups:
                [rtn addObject:stringWithID("Census Block Groups",feature)];
                break;
            case CPFBlockGroups_ACS:
                [rtn addObject:stringWithID("Census Block Groups (2015 ACS Data)",feature)];
                break;
            case CPFTracts:
                [rtn addObject:stringWithID("Census Tracts",feature)];
                break;
            case CPFVoterDistricts:
                [rtn addObject:stringWithID("Voting Districts",feature)];
                break;
            case CPFSchoolDistricts:
                [rtn addObject:stringWithID("School Districts",feature)];
                break;
            case CPFeaturesCount:
                break;
        }
    }
    return rtn;
}

- (NSArray *) valuesForFeature:(CPFeatures)feature
{
    NSArray *rtn = nil;
    
    switch (feature)
    {
        case CPFParcels:
        case CPFParcels_COM:
        case CPFParcels_RES:
        case CPFParcels_AG:
        case CPFParcels_IND:
            rtn = [self valuesForParcels];
            break;
        case CPFBlocks:
            rtn = [self valuesForBlocks];
            break;
        case CPFBlockGroups:
            rtn = [self valuesForBlocks];
            break;
        case CPFBlockGroups_ACS:
            rtn = [self valuesForBlockGroups_ACS];
            break;
        case CPFTracts:
            rtn = [self valuesForBlocks];
            break;
        case CPFVoterDistricts:
            rtn = [NSArray arrayWithObjects:@"", nil];
            break;
        case CPFLandUse:
            rtn = [self valuesForLandUse];
            break;
        case CPFeaturesCount:
            break;
            
        default:
            break;
    }
    return rtn;
}
- (NSArray *) valuesForParcels
{
    NSMutableArray *rtn = NSMutableArray.new;
/*PID,BasePointX,BasePointY,NumPoints,NumLoops,PolyPartLen,Points,PARCELPOLY.id,HOMESTEAD,USE1_DESC,USE2_DESC,TAX_EXEMPT,EMV_TOTAL,EMV_LAND,EMV_BLDG,ACRES_POLY,SPEC_ASSES,OWNER_NAME,SALE_DATE,SALE_VALUE,NUMLINKEDPARCELS  FROM PARCELPOLY,PARCELPOLY_index,PROPINFO WHERE PARCELPOLY.id=PARCELPOLY_index.id AND PROPINFO.PIN=PARCELPOLY.PID AND maxX>=%f AND minX<=%f AND*/
    for (CPParcelValues value = 0;value<CPParcelVCount;value++)
    {
        switch (value)
        {
            case CPParcelVNone:
                [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","None","",0]];
                break;
            case CPParcelVTotTax:
                [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total Tax","TOTAL_TAX",(int)value]];
                break;
            case CPParcelVTotEMV:
                [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total EMV","EMV_TOTAL",(int)value]];
                break;
            case CPParcelVBuildEMV:
                [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Building EMV","EMV_BLDG",(int)value]];
                break;
            case CPParcelVLandEMV:
                [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Land EMV","EMV_LAND",(int)value]];
                break;
            case CPParcelVLastSalePrice:
                [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Last Sale Price","SALE_VALUE",(int)value]];
                break;
            case CPParcelVCount:
                break;
        }
    }
    return rtn;
}
- (NSArray *) valuesForLandUse
{
    NSMutableArray *rtn = NSMutableArray.new;
    
    for (CPLandUseValues value = 0;value<CPLandUseVCount;value++)
    {
        switch (value)
        {
            case CPLandUseVNone:
                [rtn addObject:stringWithID("None",value)];
                break;
            case CPLandUseVCodes:
                [rtn addObject:stringWithID("Land Use Codes",value)];
                break;
            case CPLandUseVCount:
                break;
        }
    }
    return rtn;
}
- (NSArray *) adjustmentOptions
{
    NSMutableArray *rtn = NSMutableArray.new;
    
    for (CPAdjustmentValues value = 0;value<CPAdjustCount;value++)
    {
        switch (value)
        {
            case CPAdjustRawCounts:
                [rtn addObject:stringWithID("None (raw counts)",value)];
               break;

            case CPAdjustCountPerSQMile:
                [rtn addObject:stringWithID("Per Square Mile",value)];
                break;

            case CPAdjustCountPerAcre:
                [rtn addObject:stringWithID("Per Acre",value)];
                break;

            case CPAdjustCountPerHousingUnit:
                [rtn addObject:stringWithID("Per Housing Unit",value)];
                break;

            case CPAdjustPctOfTotalPop:
                [rtn addObject:stringWithID("As Percent of Total Population",value)];
                break;

            case CPAdjustPctOfTotalHousingUnits:
                [rtn addObject:stringWithID("As Percent of Total Housing Units",value)];
                break;
                
            case CPAdjustCount:
                break;
        }
    }
    return rtn;
}
- (NSArray *) valuesForBlocks
{
    NSMutableArray *rtn = NSMutableArray.new;
    
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","None","",0,0]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Total number of people","POPTOTAL",0,1]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Total housing units","B00002e1",0,2]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Households with 1 person alone","LIVEDALONE",0,3]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Family households with children and headed by a married couple","MARRKIDS",0,4]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Family households with children and headed by a single person or unmarried people","UNMARRKIDS",0,5]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Family households with no children","FAMNOKIDS",0,6]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Other households that are not families and with more than 1 person","NONFAMILY",0,7]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 0 to 4","M_0_4",1,8]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 5 to 9","M_5_9",1,9]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 10 to 14","M_10_14",1,10]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 15 to 19","M_15_19",1,11]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 20 to 24","M_20_24",1,12]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 25 to 29","M_25_29",1,13]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 30 to 34","M_30_34",1,14]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 35 to 39","M_35_39",1,15]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 40 to 44","M_40_44",1,16]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 45 to 49","M_45_49",1,17]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 50 to 54","M_50_54",1,18]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 55 to 59","M_55_59",1,19]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 60 to 64","M_60_64",1,20]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 65 to 69","M_65_69",1,21]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 70 to 74","M_70_74",1,22]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 75 to 79","M_75_79",1,23]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males age 80 to 84","M_80_84",1,24]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Males over age 85","M_OVER85",1,25]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 0 to 4","F_0_4",1,26]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 5 to 9","F_5_9",1,27]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 10 to 14","F_10_14",1,28]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 15 to 19","F_15_19",1,29]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 20 to 24","F_20_24",1,30]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 25 to 29","F_25_29",1,31]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 30 to 34","F_30_34",1,32]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 35 to 39","F_35_39",1,33]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 40 to 44","F_40_44",1,34]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 45 to 49","F_45_49",1,35]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 50 to 54","F_50_54",1,36]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 55 to 59","F_55_59",1,37]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 60 to 64","F_60_64",1,38]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 65 to 69","F_65_69",1,39]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 70 to 74","F_70_74",1,40]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 75 to 79","F_75_79",1,41]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females age 80 to 84","F_80_84",1,42]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Females over age 85","F_OVER85",1,43]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population that identifies as white only and non-Hispanic","WHITENH",0,44]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population that identifies as black only and non-Hispanic","BLACKNH",0,45]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population that identifies as American Indian only and non-Hispanic","AMINDNH",0,46]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population that identifies as Asian/Asian-American only and non-Hispanic","ASIANNH",0,47]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population that identifies as Pacific Islander only and non-Hispanic","PACIFICNH",0,48]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population that identifies as other race and non-Hispanic","OTHERNH",0,49]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population that identifies as multi-racial and non-Hispanic","MULTRACENH",0,50]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population that identifies as Hispanic in combination with any race","HISPPOP",0,51]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population that identifies as non-Hispanic)","NOTHISPPOP",0,52]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Total housing units","HUTOTAL",0,53]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Total households, also number of occupied housing units","HHTOTAL",0,54]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population in households and not in group quarters","POPINHH",0,55]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Average household size","AVGHHSIZE",0,56]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population in group quarters","POPINGQ",0,57]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Share of households that own their housing","HOMEOWNPCT",0,58]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Owner households or owner-occupied units","OWNEROCC",0,59]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Renter households or renter-occupied units","RENTEROCC",0,60]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Vacant housing units","VACANT",0,61]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population (age 5+) used as denominator in % calculations","POPOVER5",0,62]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population age 16+","POPOVER16",0,63]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population age 18+","POPOVER18",0,64]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Population age 65+","POPOVER65",0,65]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","quality control flag should be 0","ERRORFLAG",0,66]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Median age for area","MEDIANAGE",0,67]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Housieholds with children ages 0-17 present","HH_UNDER18",0,68]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x05%i\x04%i","Households with senior citizens ages 65+ present","HH_65OVER",0,69]];
    return rtn;
}

- (NSArray *) valuesForBlockGroups_ACS
{
    NSMutableArray *rtn = NSMutableArray.new;

    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Number of people participating in sample of completed surveys","B00001e1",0]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Number of housing units represented in sample of completed surveys","B00002e1",1]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total population","POPTOTAL",2]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population in households and not in GQ","POPINHH",3]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total households","HHTOTAL",4]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Average household size","AVGHHSIZE",5]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Households with 1 person","LIVEDALONE",6]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Family households with children and headed by a married couple","MARRKIDS",7]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Family households with children and headed by a single person or unmarried people","UNMARRKIDS",8]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Family households with no children","FAMNOKIDS",9]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Other households that are not families and with more than 1 person","NONFAMILY",10]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 0 to 4","M_0_4",11]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 5 to 9","M_5_9",12]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 10 to 14","M_10_14",13]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 15 to 19","M_15_19",14]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 20 to 24","M_20_24",15]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 25 to 29","M_25_29",16]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 30 to 34","M_30_34",17]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 35 to 39","M_35_39",18]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 40 to 44","M_40_44",19]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 45 to 49","M_45_49",20]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 50 to 54","M_50_54",21]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 55 to 59","M_55_59",22]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 60 to 64","M_60_64",23]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 65 to 69","M_65_69",24]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 70 to 74","M_70_74",25]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 75 to 79","M_75_79",26]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 80 to 84","M_80_84",27]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 85+","M_OVER85",28]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 0 to 4","F_0_4",29]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 5 to 9","F_5_9",30]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 10 to 14","F_10_14",31]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 15 to 19","F_15_19",32]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 20 to 24","F_20_24",33]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 25 to 29","F_25_29",34]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 30 to 34","F_30_34",35]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 35 to 39","F_35_39",36]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 40 to 44","F_40_44",37]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 45 to 49","F_45_49",38]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 50 to 54","F_50_54",39]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 55 to 59","F_55_59",40]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 60 to 64","F_60_64",41]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 65 to 69","F_65_69",42]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 70 to 74","F_70_74",43]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 75 to 79","F_75_79",44]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 80 to 84","F_80_84",45]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 85+","F_OVER85",46]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population age 5+ used as denominator in % calculations","POPOVER5",47]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population age 16+","POPOVER16",48]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population age 18+","POPOVER18",49]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population age under 18","AGEUNDER18",50]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population age 18 to 39","AGE18_39",51]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population age 40 to 64","AGE40_64",52]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population age 65+","AGE65UP",53]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as white only and non-Hispanic","WHITENH",54]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as black only and non-Hispanic","BLACKNH",55]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as American Indian only and non-Hispanic","AMINDNH",56]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as Asian/Asian-American only and non-Hispanic","ASIANNH",57]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as Pacific Islander only and non-Hispanic","PACIFICNH",58]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as other race and non-Hispanic","OTHERNH",59]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as multi-racial and non-Hispanic","MULTRACENH",60]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as Hispanic in combination with any race","HISPPOP",61]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as non-Hispanic","NOTHISPPOP",62]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Adult population","POPOVER25",63]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Adult population that did not complete high school","LESSHS",64]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Adult population that competed high school","HIGHSCHOOL",65]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Adult population that attended some college","SOMECOLLEG",66]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Adult population that competed 2-year degree","ASSOCIATE",67]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Adult population that competed bachelor's degree","BACHELORS",68]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Adult population that competed post-bac graduate or professional degree","GRADPROF",69]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Employed population used as denominator in % calculations","WORKDENOM",70]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Drive alone to work","DROVEALONE",71]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Drive or ride with others to work","CARPOOL",72]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Take public transit to work","PUBTRANSIT",73]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Walk to work","WALKTOWORK",74]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Commuted to work bicycling or by taxi or some other way","OTHCOMMUTE",75]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Worked at home and did not commute","WORKATHOME",76]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Employed commuters excluding work-at-home used as denominator in % calculations","JTWDENOM",77]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Commuted 1 to 9 minutes to work","JTWLT10",78]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Commuted 10 to 14 minutes to work","JTW10TO14",79]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Commuted 15 to 19 minutes to work","JTW15TO19",80]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Commuted 20 to 24 minutes to work","JTW20TO24",81]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Commuted 25 to 29 minutes to work","JTW25TO29",82]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Commuted 30 to 34 minutes to work","JTW30TO34",83]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Commuted 35 to 44 minutes to work","JTW35TO44",84]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Commuted 45 to 59 minutes to work","JTW45TO59",85]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Commuted 60 minutes or longer","JTW60PLUS",86]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total minutes of commuting used as numerator","AGGCOMMUTE",87]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Mean average commute length","AVGCOMMUTE",88]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Number of vehicles available to households","VEHICLESN",89]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Households with 0 vehicle","HH_NOVEH",90]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Households with 1 vehicle","HH_1VEH",91]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Households with 2 or more vehicles","HH_MULTVEH",92]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","US citizens who were born in the US or PR","USBORNCIT",93]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","US citizens who were born abroad","FORBORNCIT",94]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Non citizens who were born abroad","FORBORNNOT",95]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total noninstitutionalized civilian population used as denominator in disability % calculations","CDENOM",96]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total noninstitutionalized civilian population age 0 to 17 used as denominator in disability % calculations","CDENOM_017",97]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total noninstitutionalized civilian population age 5 to 17 used as denominator in disability % calculations","CDENOM_517",98]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total noninstitutionalized civilian population age 18 to 64 used as denominator in disability % calculations","CDENOM1864",99]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total noninstitutionalized civilian population age 65+ used as denominator in disability % calculations","CDENOM65UP",100]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People with any disability","ANYDIS",101]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 0 to 17 with any disability","ANYDIS_017",102]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 18 to 64 with any disability","ANYDIS1864",103]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 65+ with any disability","ANYDIS65UP",104]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People with a hearing difficulty","DEAF",105]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 0 to 17 with a hearing difficulty","DEAF_017",106]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 18 to 64 with a hearing difficulty","DEAF1864",107]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 65+ with a hearing difficulty","DEAF65UP",108]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People with a vision related disability","VISION",109]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 0 to 17 with a vision related disability","VISION_017",110]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 18 to 64 with a vision related disability","VISION1864",111]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 65+ with a vision related disability","VISION65UP",112]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People with a cognitive disability","COGDIS",113]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 5 to 17 with a cognitive disability","COGDIS_517",114]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 18 to 64 with a cognitive disability","COGDIS1864",115]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 65+ with a cognitive disability","COGDIS65UP",116]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People with a ambulatory disability","AMBDIS",117]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 5 to 17 with a ambulatory disability","AMBDIS_517",118]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 18 to 64 with a ambulatory disability","AMBDIS1864",119]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 65+ with a ambulatory disability","AMBDIS65UP",120]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People with a disability that hinders self care","SELFCARE",121]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 5 to 17 with a disability that hinders self care","SELFCA_517",122]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 18 to 64 with a disability that hinders self care","SELFCA1864",123]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 65+ with a disability that hinders self care","SELFCA65UP",124]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People with a disability that hinders independent living","INDLIV",125]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 5 to 17 with a disability that hinders independent living","INDLIV_517",126]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 18 to 64 with a disability that hinders independent living","INDLIV1864",127]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","People age 65+ with a disability that hinders independent living","INDLIV65UP",128]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population 5 and over who speak English at home","ENGLISH",129]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population who speak another language and speak English very well","ESL_VWELL",130]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population who speak English less than very well","LEP",131]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Subset of LEP who speak Spanish","LEP_SPAN",132]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Subset of LEP who speak Russian","LEP_RUSS",133]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Subset of LEP who speak a Chinese language","LEP_CHIN",134]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Subset of LEP who speak Hmong","LEP_HMONG",135]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Subset of LEP who speak Vietnamese","LEP_VIET",136]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Subset of LEP who speak an African language","LEP_AFRICA",137]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Income per capita","PCI",138]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Mean average income per household","MEANHHINC",139]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Median income per household","MEDIANHHI",140]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Estimated population with income 0 to 99% of poverty threshold","POVERTYN",141]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Estimated population with income in the range 100% to 149% of poverty","POVERTY150",142]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Estimated population with income in the range 150% to 184% of poverty","POV150_185",143]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Denominator population for poverty question","POVDENOM",144]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Share of population with income 0 to 99% of poverty threshold","POV100RATE",145]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Share of population with income 0 to 149% of poverty threshold","POV150RATE",146]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Share of population with income 0 to 184% of poverty threshold","POV185RATE",147]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Estimated housing units","HUTOTAL",148]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Single family detached housing units","HUSFD",149]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Single family attached housing units","HUSFA",150]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Housing units in duplexes and 3 to 4 unit buildings","HU234",151]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Housing units in larger buildings","HUMF5",152]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Manufactured or mobile home units","HUMOBILE",153]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Other or not elsewhere classified shelters","HUOTHER",154]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Share of households that own their housing","HOMEOWNPCT",155]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Owner households or owner-occupied units","OWNEROCC",156]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households or renter-occupied units","RENTEROCC",157]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Vacant housing units","VACANT",158]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Median gross rent including utilities","MEDGRENT",159]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Median home value of ownership housing","MEDHOMEVAL",160]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners spending 30+ percent of household budget on housing","BURDOWN",161]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners spending 0 to 29 percent of household budget on housing","NOBURDOWN",162]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renters spending 30+ percent of household budget on housing","BURDRENT",163]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renters spending 0 to 29 percent of household budget on housing","NOBURDRENT",164]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total households with income used as denominator in % calculations","BURD_DENOM",165]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent $1 to $199","RLT200",166]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent in the range of $200 to $299","R200_299",167]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent in the range of $300 to $399","R300_399",168]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent in the range of $400 to $499","R400_499",169]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent in the range of $500 to $599","R500_599",170]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent in the range of $600 to $699","R600_699",171]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent in the range of $700 to $799","R700_799",172]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent in the range of $800 to $899","R800_899",173]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent in the range of $900 to $999","R900_999",174]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent in the range of $1,000 to $1,249","R1000_1249",175]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent in the range of $1,250 to $1,499","R1250_1499",176]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent in the range of $1,500 to $1,999","R1500_1999",177]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with gross rent in the range of $2,000+","R2000up",178]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households with cash rent used as denominator in percent calculations","R_DENOM",179]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home less than $40,000","VALLT40",180]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home in the range of $40,000 to $69,000","VAL40_69",181]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home in the range of $70,000 to $99,000","VAL70_99",182]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home in the range of $100,000 to $124,000","VAL100_124",183]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home in the range of $125,000 to $149,000","VAL125_149",184]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home in the range of $150,000 to $174,000","VAL150_174",185]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home in the range of $175,000 to $199,000","VAL175_199",186]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home in the range of $200,000 to $249,000","VAL200_249",187]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home in the range of $250,000 to $299,000","VAL250_299",188]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home in the range of $300,000 to $399,000","VAL300_399",189]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home in the range of $400,000 to $499,000","VAL400_499",190]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home in the range of $500,000 to $749,000","VAL500_749",191]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home in the range of $750,000 to $999,000","VAL750_999",192]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowners valuing their home at $1 million+","VAL1MIL",193]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Homeowner households used as denominator in % calculations","VAL_DENOM",194]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Households in single family detached OR townhouse units","HHSF",195]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Households in duplexes and 3 to 4 unit buildings","HH234",196]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Households in larger buildings","HHMF5",197]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Households in manufactured or mobile home units","HHMOBILE",198]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Households in other or not elsewhere classified shelters","HHOTHER",199]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population in single family detached OR townhouse units","POPSF",200]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population in duplexes and 3 to 4 unit buildings","POP234",201]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population in larger buildings","POPMF5",202]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population in manufactured or mobile home units","POPMOBILE",203]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population in other or not elsewhere classified shelters","POPOTHER",204]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Average household size in single family housing","PPHSF",205]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Average household size in duplexes and 3 to 4 unit buildings","PPH234",206]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Average household size in larger buildings","PPHMF5",207]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Average household size in manufactured or mobile home units","PPHMOBILE",208]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Average household size in other or NEC shelters","PPHOTHER",209]];
    return rtn;
}

- (NSArray *) currentTextOptions
{
    NSMutableArray * rtn = NSMutableArray.new;
    NSArray * options = [self textValuesForFeature:_currentFeature];
    
    for (NVMetroTextOptions * to in options)
    {
        NSString *desc = to.desc.copy;
        [rtn addObject:desc];
    }
    return rtn;
}
- (NSArray *) textValuesForFeature:(CPFeatures)feature
{
    NSArray *rtn = nil;
    
    switch (feature)
    {
        case CPFParcels:
        case CPFParcels_COM:
        case CPFParcels_RES:
        case CPFParcels_AG:
        case CPFParcels_IND:
            rtn = [self textValuesForParcels];
            break;
        case CPFBlocks:
        case CPFBlockGroups:
        case CPFBlockGroups_ACS:
        case CPFTracts:
        case CPFVoterDistricts:
        case CPFLandUse:
            rtn = [self textValuesForBlocks];
            break;
        case CPFeaturesCount:
            break;
            
        default:
            break;
    }
    return rtn;
}
- (NSArray *) textValuesForParcels
{
    int i=0;
    NSMutableArray * rtn = NSMutableArray.new;
    NVMetroTextOptions *to = NVMetroTextOptions.new;
    to.desc = [NSString stringWithFormat:@"%s\x03\x04%i","No Text",i++];
    [rtn addObject:to];
    to = NVMetroTextOptions.new;
    to.desc = [NSString stringWithFormat:@"%s\x03\x04%i","Auto Text",i++];
    to.numTextFields = -1;
    [rtn addObject:to];
    to = NVMetroTextOptions.new;
    to.desc = [NSString stringWithFormat:@"%s\x03\x04%i","Total EMV/Taxpayer",i++];
    to.numTextFields = 4;
    to.fields = @"EMV_TOTAL,OWNER_NAME,OWNER_MORE,TAX_NAME";
    to.formats = [NSArray arrayWithObjects:[NSNumber numberWithInt:TXTAdjustDollars],[NSNumber numberWithInt:TXTAdjustOwnerNames],[NSNumber numberWithInt:TXTAdjustOwnerNames],[NSNumber numberWithInt:TXTAdjustOwnerNames], nil];
    [rtn addObject:to];

    to = NVMetroTextOptions.new;
    to.desc = [NSString stringWithFormat:@"%s\x03\x04%i","Land EMV/Acres/Land EMV per Acre",i++];
    to.numTextFields = 3;
    to.fields = @"EMV_LAND,ACRES_POLY,EMV_LAND";
    to.formats = [NSArray arrayWithObjects:[NSNumber numberWithInt:TXTAdjustDollars],[NSNumber numberWithInt:TXTAdjustAcres],[NSNumber numberWithInt:TXTAdjustDollarsPerAcre], nil];
    [rtn addObject:to];
    
    to = NVMetroTextOptions.new;
    to.desc = [NSString stringWithFormat:@"%s\x03\x04%i","Owner/Land EMV/Acres/Land EMV per Acre",i++];
    to.numTextFields = 6;
    to.fields = @"OWNER_NAME,OWNER_MORE,TAX_NAME,EMV_LAND,ACRES_POLY,EMV_LAND";
    to.formats = [NSArray arrayWithObjects:[NSNumber numberWithInt:TXTAdjustOwnerNames],[NSNumber numberWithInt:TXTAdjustOwnerNames],[NSNumber numberWithInt:TXTAdjustOwnerNames],[NSNumber numberWithInt:TXTAdjustDollars],[NSNumber numberWithInt:TXTAdjustAcres],[NSNumber numberWithInt:TXTAdjustDollarsPerAcre], nil];
    [rtn addObject:to];
    
    to = NVMetroTextOptions.new;
    to.desc = [NSString stringWithFormat:@"%s\x03\x04%i","Last Sale Price/Last Sale Date/Owner",i++];
    to.numTextFields = 5;
    to.fields = @"SALE_VALUE,SALE_DATE,OWNER_NAME,OWNER_MORE,TAX_NAME";
    to.formats = [NSArray arrayWithObjects:[NSNumber numberWithInt:TXTAdjustDollars],[NSNumber numberWithInt:TXTAdjustDate],[NSNumber numberWithInt:TXTAdjustOwnerNames],[NSNumber numberWithInt:TXTAdjustOwnerNames],[NSNumber numberWithInt:TXTAdjustOwnerNames], nil];
    [rtn addObject:to];
    return rtn;
}
- (NSArray *) textValuesForBlocks
{
    int i=0;
    NSMutableArray * rtn = NSMutableArray.new;
    NVMetroTextOptions *to = NVMetroTextOptions.new;
    to.desc = [NSString stringWithFormat:@"%s\x03\x04%i","No Text",i++];
    [rtn addObject:to];
    to = NVMetroTextOptions.new;
    to.desc = [NSString stringWithFormat:@"%s\x03\x04%i","Auto Text",i++];
    to.numTextFields = -1;
    [rtn addObject:to];
    return rtn;
}

- (void) currentTextSelection:(int)index
{
    NSArray * textOptions = [self textValuesForFeature:_currentFeature];
    if (index < textOptions.count)
    {
        _currentTextOption = textOptions[index];
        currentTextValues[_currentFeature] = index;
    }
}

-(NVMetroTextOptions*) textOptionsForAreas
{
    NVMetroTextOptions*to = NVMetroTextOptions.new;
    to.numTextFields = 1;
    to.desc = @"Boundary Name";
    to.fields = @"NAME";
    to.formats = [NSArray arrayWithObjects:[NSNumber numberWithInt:TXTAdjustNone], nil];
    return to;
}
@end

