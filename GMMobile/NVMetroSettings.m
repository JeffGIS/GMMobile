//
//  NVMetroSettings.m
//  NVMobile
//
//  Created by Jeff Smith on 12/23/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import "NVMetroSettings.h"

static int currentValues[CPFeaturesCount];

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
        self.currentFeature = CPFTracts;
        self.currentAdjustmentValue = CPAdjustCountPerSQMile;
        currentValues[self.currentFeature] = self.currentFeatureValue = 1;
    }
    
    return self;
}

- (NSString *) currentFeatureText
{
    NSString * rtn = stringWithoutID([self features][_currentFeature]);
    return rtn;
}

- (NSString *) currentValueText
{
    NSArray * values = [self valuesForFeature:_currentFeature];
    NSString * rtn = stringWithoutID(values[currentValues[_currentFeature]]);
    return rtn;
}
- (NSString *) currentAdjustmentText
{
    NSArray * values = [self adjustmentOptions];
    NSString * rtn = stringWithoutID(values[_currentAdjustmentValue]);
    return rtn;
}
- (NSString *) currentValueField
{
    NSArray * values = [self valuesForFeature:_currentFeature];
    NSString * rtn = textAfter(values[currentValues[_currentFeature]], @"\x03");
    rtn = textBefore (rtn,@"\x04");
    return rtn;
}
- (void) setCurrentValue:(NSInteger)value
{
    currentValues[_currentFeature] = (int)value;
    _currentFeatureValue = (int)value;
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
            case CPFLandUse:
                [rtn addObject:stringWithID("Land Use",feature)];
                break;
            case CPFBlocks:
                [rtn addObject:stringWithID("Blocks",feature)];
                break;
            case CPFBlockGroups:
                [rtn addObject:stringWithID("Block Groups",feature)];
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
            rtn = [self valuesForParcels];
            break;
        case CPFBlocks:
            rtn = [self valuesForBlocks];
            break;
        case CPFBlockGroups:
            rtn = [self valuesForBlocks];
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
    
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","None","",0]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total number of people","POPTOTAL",1]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total housing units","B00002e1",2]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Households with 1 person alone","LIVEDALONE",3]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Family households with children and headed by a married couple","MARRKIDS",4]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Family households with children and headed by a single person or unmarried people","UNMARRKIDS",5]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Family households with no children","FAMNOKIDS",6]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Other households that are not families and with more than 1 person","NONFAMILY",7]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 0 to 4","M_0_4",8]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 5 to 9","M_5_9",9]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 10 to 14","M_10_14",10]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 15 to 19","M_15_19",11]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 20 to 24","M_20_24",12]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 25 to 29","M_25_29",13]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 30 to 34","M_30_34",14]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 35 to 39","M_35_39",15]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 40 to 44","M_40_44",16]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 45 to 49","M_45_49",17]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 50 to 54","M_50_54",18]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 55 to 59","M_55_59",19]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 60 to 64","M_60_64",20]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 65 to 69","M_65_69",21]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 70 to 74","M_70_74",22]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 75 to 79","M_75_79",23]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males age 80 to 84","M_80_84",24]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Males over age 85","M_OVER85",25]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 0 to 4","F_0_4",26]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 5 to 9","F_5_9",27]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 10 to 14","F_10_14",28]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 15 to 19","F_15_19",29]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 20 to 24","F_20_24",30]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 25 to 29","F_25_29",31]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 30 to 34","F_30_34",32]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 35 to 39","F_35_39",33]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 40 to 44","F_40_44",34]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 45 to 49","F_45_49",35]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 50 to 54","F_50_54",36]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 55 to 59","F_55_59",37]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 60 to 64","F_60_64",38]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 65 to 69","F_65_69",39]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 70 to 74","F_70_74",40]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 75 to 79","F_75_79",41]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females age 80 to 84","F_80_84",42]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Females over age 85","F_OVER85",43]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as white only and non-Hispanic","WHITENH",44]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as black only and non-Hispanic","BLACKNH",45]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as American Indian only and non-Hispanic","AMINDNH",46]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as Asian/Asian-American only and non-Hispanic","ASIANNH",47]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as Pacific Islander only and non-Hispanic","PACIFICNH",48]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as other race and non-Hispanic","OTHERNH",49]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as multi-racial and non-Hispanic","MULTRACENH",50]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as Hispanic in combination with any race","HISPPOP",51]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population that identifies as non-Hispanic)","NOTHISPPOP",52]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total housing units","HUTOTAL",53]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Total households, also number of occupied housing units","HHTOTAL",54]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population in households and not in group quarters","POPINHH",55]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Average household size","AVGHHSIZE",56]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population in group quarters","POPINGQ",57]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Share of households that own their housing","HOMEOWNPCT",58]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Owner households or owner-occupied units","OWNEROCC",59]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Renter households or renter-occupied units","RENTEROCC",60]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Vacant housing units;","VACANT",61]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population (age 5+) used as denominator in % calculations","POPOVER5",62]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population age 16+","POPOVER16",63]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population age 18+","POPOVER18",64]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Population age 65+","POPOVER65",65]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","quality control flag should be 0","ERRORFLAG",66]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Median age for area","MEDIANAGE",67]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Housieholds with children ages 0-17 present","HH_UNDER18",68]];
    [rtn addObject:[NSString stringWithFormat:@"%s\x03%s\x04%i","Households with senior citizens ages 65+ present","HH_65OVER",69]];
    return rtn;
}

@end
