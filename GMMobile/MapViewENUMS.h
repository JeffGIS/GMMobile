//  MapViewENUMS.h
//  GMMobile

#ifndef GMMobile_MapViewENUMS_h
#define GMMobile_MapViewENUMS_h

typedef NS_ENUM(NSInteger, PropertyTableViewSetting)
{
    PropertyTableViewSettingDefault,
    PropertyTableViewSettingOptions,
    PropertyTableViewSettingPropertyReport,
    PropertyTableViewSettingPropertyHistory,
    PropertyTableViewSettingCountyRecord,
    PropertyTableViewSettingZillow,
    PropertyTableViewSettingStreetView,
    PropertyTableViewSettingStreetside,
    PropertyTableViewSettingCensusArea,
    PropertyTableViewSettingParcelText,
    PropertyTableViewSettingColorParcels,
    PropertyTableViewSettingSetTargetParcel,
    PropertyTableViewSettingFlyover,
    PropertyTableViewSettingPropList,
    PropertyTableViewSettingDestinations,
    PropertyTableViewSettingRoute,
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
    ParcelTextSettingLastSale,
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
    ParcelColorSettingLastSale,
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
    CrimePointSettingAddToCurrentList,
    CrimePointSettingAddToNewList,
    CrimePointSettingAddAllToCurrentList,
    CrimePointSettingAddAllToNewList,
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
