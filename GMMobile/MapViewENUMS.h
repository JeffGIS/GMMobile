//
//  MapViewENUMS.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 8/14/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#ifndef GMMobile_MapViewENUMS_h
#define GMMobile_MapViewENUMS_h

typedef NS_ENUM(NSInteger, PropertyTableViewSetting)
{
    PropertyTableViewSettingDefault,
    PropertyTableViewSettingOptions,
    PropertyTableViewSettingPropertyReport,
    PropertyTableViewSettingHCWebsite,
    PropertyTableViewSettingStreetView,
    PropertyTableViewSettingCensusArea,
    PropertyTableViewSettingPropList,
    PropertyTableViewSettingDestinations,
};

typedef NS_ENUM(NSInteger, CensusZoomSetting)
{
    CensusZoomSettingCancel,
    CensusZoomSettingBlock,
    CensusZoomSettingBlockGroup,
    CensusZoomSettingTract,
};

typedef NS_ENUM(NSInteger, ParcelTextSetting)
{
    ParcelTextSettingCancel,
    ParcelTextSettingOwnerTax,
    ParcelTextSettingBuildingNum,
    ParcelTextSettingEMVLand,
    ParcelTextSettingEMVLandPerAcre,
};

typedef NS_ENUM(NSInteger, ParcelColorSetting)
{
    ParcelColorSettingCancel,
    ParcelColorSettingTotEMV,
    ParcelColorSettingBuildingEMV,
    ParcelColorSettingLandEMV,
    ParcelColorSettingLandEMVPerAcre,
    ParcelColorSettingHomestead,
    ParcelColorSettingResCom,
    ParcelColorSettingSpecialAssessment,
    ParcelColorSettingTaxExempt,
    ParcelColorSettingTaxForfeit,

};

typedef NS_ENUM(NSInteger, SewerPipeSetting)
{
    SewerPipeSettingDefault,
    SewerPipeSettingAttributes,
    SewerPipeSettingTraceUp,
    SewerPipeSettingTraceDown,
    SewerPipeSettingRemoveTrace,
    SewerPipeSettingUpdateCleanDate,
    SewerPipeSettingUpdateNotes,
};

typedef NS_ENUM(NSInteger, CustomSetting)
{
    CustomSettingDefault,
    CustomSettingSnapToNode,
    CustomSettingSnapToLine,
};

typedef NS_ENUM(NSInteger, AlleyWallSetting)
{
    AlleyWallSettingDefault,
    AlleyWallSettingMoveWallPoint,
    AlleyWallSettingDeleteWallPoint,
    AlleyWallSettingEditWallAttributes,
    AlleyWallSettingViewWallPhotos,
    AlleyWallSettingViewInsetWallPhotos,
};

typedef NS_ENUM(NSInteger, CrimePointSetting)
{
    CrimePointSettingDefault,
    CrimePointSettingDisplayReport,
    CrimePointSettingPerformFlyAround,
    CrimePointSettingDisplayStreetView,
};

typedef NS_ENUM(NSInteger, AlleyLineSetting)
{
    AlleyLineSettingDefault,
    AlleyLineSettingToggleCompletionStatus,
};

typedef NS_ENUM(NSInteger, MapTypeSetting)
{
    MapTypeSettingStandard,
    MapTypeSettingHybrid,
};

typedef NS_ENUM(NSInteger, DigitizationMode)
{
    DigitizationModeCustom,
    DigitizationModeAlleyWallNew,
    DigitizationModeAlleyWallMove,
    DigitizationModeSewer,
    DigitizationModeProperty,
    DigitizationModeCurbRamps,
};

typedef NS_ENUM(NSInteger, AlleyStatusSetting)
{
    AlleyStatusSettingDefault,
    AlleyStatusSettingCenterline,
    AlleyStatusSettingWall,
};

#endif