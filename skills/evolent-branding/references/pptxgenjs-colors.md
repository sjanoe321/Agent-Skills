# Evolent PptxgenJS Reference

When creating Evolent-branded presentations from scratch using PptxgenJS, use these constants and patterns.

## Color Constants

```javascript
const EVOLENT = {
  // Primary
  navy:       '020623',
  white:      'FFFFFF',
  plum:       '7B1C92',
  coolGray:   '9FA7AE',
  midGray:    '89898C',
  bgAlt:      'F5F5F7',

  // Gradient accent ramp (left to right)
  deepPurple:  '5D3791',  // Accent 1
  purpleBlue:  '4C51A6',  // Accent 2
  blue:        '3475C1',  // Accent 3 / hyperlink
  skyBlue:     '17A5E6',  // Accent 4
  cyan:        '08DCE2',  // Accent 5
  mint:        '08F0D4',  // Accent 6

  // Intermediate gradient stops
  purple:      '692483',
  lightCyan:   '09C9EE',
};

// Chart color sequence (use in order)
const CHART_COLORS = [
  EVOLENT.deepPurple,
  EVOLENT.blue,
  EVOLENT.skyBlue,
  EVOLENT.cyan,
  EVOLENT.purpleBlue,
  EVOLENT.mint,
];
```

## Gradient Bar Helper

Add this to the top of every slide (simulates the gradient bar with adjacent colored rectangles):

```javascript
function addGradientBar(slide) {
  const stops = [
    { color: '5D3791', x: 0.00 },
    { color: '692483', x: 1.25 },
    { color: '4C51A6', x: 2.50 },
    { color: '3475C1', x: 3.75 },
    { color: '17A5E6', x: 5.00 },
    { color: '09C9EE', x: 6.25 },
    { color: '08DCE2', x: 7.50 },
    { color: '08F0D4', x: 8.75 },
  ];
  stops.forEach(s => {
    slide.addShape('rect', {
      x: s.x,
      y: 0,
      w: 1.30,  // slight overlap to avoid gaps
      h: 0.06,
      fill: { color: s.color },
      line: { width: 0 },
    });
  });
}
```

## Footer Helper

```javascript
function addFooter(slide, pageNum) {
  slide.addText(
    `Evolent  |  Confidential—Do not distribute  |  ${pageNum}`,
    {
      x: 4.0,
      y: 7.15,
      w: 5.5,
      h: 0.3,
      fontSize: 8,
      fontFace: 'Arial',
      color: EVOLENT.midGray,
      align: 'right',
    }
  );
}
```

## Standard Slide Patterns

### Title Slide (Dark Background)

```javascript
function createTitleSlide(pptx, title, subtitle) {
  const slide = pptx.addSlide();
  slide.background = { fill: EVOLENT.navy };
  addGradientBar(slide);
  slide.addText(title, {
    x: 0.8, y: 2.0, w: 8.4, h: 1.5,
    fontSize: 40, fontFace: 'Arial', bold: true,
    color: EVOLENT.white,
  });
  if (subtitle) {
    slide.addText(subtitle, {
      x: 0.8, y: 3.5, w: 8.4, h: 0.8,
      fontSize: 18, fontFace: 'Arial',
      color: EVOLENT.coolGray,
    });
  }
  addFooter(slide, 1);
  return slide;
}
```

### Content Slide (White Background)

```javascript
function createContentSlide(pptx, heading, pageNum) {
  const slide = pptx.addSlide();
  slide.background = { fill: EVOLENT.white };
  addGradientBar(slide);
  slide.addText(heading, {
    x: 0.8, y: 0.4, w: 8.4, h: 0.7,
    fontSize: 28, fontFace: 'Arial', bold: true,
    color: EVOLENT.navy,
  });
  addFooter(slide, pageNum);
  return slide;
}
```

### Stat Callout Slide

```javascript
function createStatSlide(pptx, stat, label, context, pageNum) {
  const slide = createContentSlide(pptx, '', pageNum);
  slide.addText(stat, {
    x: 0.8, y: 1.5, w: 8.4, h: 1.5,
    fontSize: 64, fontFace: 'Arial', bold: true,
    color: EVOLENT.deepPurple, align: 'center',
  });
  slide.addText(label, {
    x: 0.8, y: 3.2, w: 8.4, h: 0.6,
    fontSize: 20, fontFace: 'Arial', bold: true,
    color: EVOLENT.navy, align: 'center',
  });
  if (context) {
    slide.addText(context, {
      x: 1.5, y: 4.0, w: 7.0, h: 1.0,
      fontSize: 14, fontFace: 'Arial',
      color: EVOLENT.midGray, align: 'center',
    });
  }
  return slide;
}
```

## Table Styling

```javascript
const EVOLENT_TABLE_STYLE = {
  headerRow: {
    fill: { color: EVOLENT.navy },
    color: EVOLENT.white,
    fontSize: 12,
    fontFace: 'Arial',
    bold: true,
    align: 'left',
  },
  evenRow: {
    fill: { color: EVOLENT.bgAlt },
    fontSize: 11,
    fontFace: 'Arial',
    color: EVOLENT.navy,
  },
  oddRow: {
    fill: { color: EVOLENT.white },
    fontSize: 11,
    fontFace: 'Arial',
    color: EVOLENT.navy,
  },
  border: { type: 'solid', color: EVOLENT.coolGray, pt: 0.5 },
};
```

## Chart Defaults

```javascript
const EVOLENT_CHART_OPTS = {
  showLegend: true,
  legendPos: 'b',
  legendFontFace: 'Arial',
  legendFontSize: 10,
  legendColor: EVOLENT.midGray,
  catAxisLabelColor: EVOLENT.midGray,
  catAxisLabelFontFace: 'Arial',
  catAxisLabelFontSize: 10,
  valAxisLabelColor: EVOLENT.midGray,
  valAxisLabelFontFace: 'Arial',
  valAxisLabelFontSize: 10,
  chartColors: CHART_COLORS,
};
```
