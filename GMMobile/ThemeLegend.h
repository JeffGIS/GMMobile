//  ThemeLegend.h
//  GMMobile

@import UIKit;
#import "ThemeTypes.h"
#import "ThemeLegendCell.h"

@interface ThemeLegend : NSObject

@property ThemeTypes type;             // legend type
@property int numCells;         // number of desired cells. Actual number in cells
                                // array may differ
@property int numColumns;
@property int numDecimals;
@property BOOL usePointSymbols; // if true each cell has a point symbol which is displayed
                                // instead of the bar chart.
@property BOOL showSymbolAsBarChart;
@property BOOL useClassColors;  // if true the symbol color comes from each ThemeLegendCell
                                // otherwise use symbolDefaultColor
@property BOOL appendClassCount;// if true class count is appended to class label.
                                // class count is displayed in parenthesis right justified
@property float aspectRatio;    // width/height
@property float pctBorder;      // border width as percentage of largest dimension
@property float pctTitle;       // percentage of legend height allocated to title
@property float pctMargin;      // outer margin as percentage of largest dimension
@property float pctInnerMargin; // inner margin as percentage of largest dimension
@property float pctSymbol;      // percentage of class allocated to symbol

@property UIColor*borderColor;  // color of outer border
@property UIColor*titleBkColor; // color of title background
@property UIColor*titleTxColor; // color of title text
@property UIColor*labelBkColor; // color of class background
@property UIColor*labelTxColor; // color of class text
@property UIColor*symbolDefaultColor; // default color of symbol

@property NSString* title;      //current legend title
@property NSMutableArray *titles; //possible titles
@property (nonatomic)int currentTitleIndex; //index of current title
@property NSMutableArray *cells;  //ThemeLegendCell array

@property (nonatomic) BOOL drawOnMap, isDraggedLandscape, isDraggedPortrait, hasColors;
@property (nonatomic) CGPoint portraitMapOrigin, landscapeMapOrigin;
@property (nonatomic) CGFloat scrollYPosition;
@property MNMXCORD maxValBounds;
@property (readonly) CGFloat headerHeight;

@end
