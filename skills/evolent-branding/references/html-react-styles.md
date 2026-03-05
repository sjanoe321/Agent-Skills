# Evolent HTML & React Reference

CSS custom properties, React component patterns, and Tailwind configuration for Evolent-branded web artifacts.

## CSS Custom Properties

```css
:root {
  /* Primary */
  --evolent-navy: #020623;
  --evolent-white: #FFFFFF;
  --evolent-plum: #7B1C92;
  --evolent-cool-gray: #9FA7AE;
  --evolent-mid-gray: #89898C;
  --evolent-bg-alt: #F5F5F7;

  /* Gradient accent ramp */
  --evolent-deep-purple: #5D3791;
  --evolent-purple-blue: #4C51A6;
  --evolent-blue: #3475C1;
  --evolent-sky-blue: #17A5E6;
  --evolent-cyan: #08DCE2;
  --evolent-mint: #08F0D4;

  /* Gradient */
  --evolent-gradient: linear-gradient(to right, #5D3791, #692483, #4C51A6, #3475C1, #17A5E6, #09C9EE, #08DCE2, #08F0D4);

  /* Typography */
  --font-primary: Arial, Helvetica, sans-serif;
}
```

## Tailwind Custom Config (inline style approach)

Since Tailwind in Claude artifacts uses pre-built classes, apply Evolent colors via inline styles or className overrides:

```jsx
// Gradient bar component
const GradientBar = ({ height = '4px' }) => (
  <div
    style={{
      height,
      background: 'linear-gradient(to right, #5D3791, #692483, #4C51A6, #3475C1, #17A5E6, #09C9EE, #08DCE2, #08F0D4)',
      width: '100%',
    }}
  />
);

// Evolent-styled card
const EvolentCard = ({ title, children }) => (
  <div className="bg-white rounded-lg shadow-sm overflow-hidden">
    <div
      style={{
        height: '4px',
        background: 'linear-gradient(to right, #5D3791, #4C51A6, #3475C1, #17A5E6, #08DCE2, #08F0D4)',
      }}
    />
    <div className="p-6">
      <h3 style={{ color: '#020623', fontFamily: 'Arial, sans-serif', fontWeight: 'bold', fontSize: '18px' }}>
        {title}
      </h3>
      <div style={{ color: '#020623', fontFamily: 'Arial, sans-serif', fontSize: '14px' }}>
        {children}
      </div>
    </div>
  </div>
);

// Stat callout
const StatCallout = ({ value, label, sublabel }) => (
  <div className="text-center p-8">
    <div style={{ color: '#5D3791', fontFamily: 'Arial, sans-serif', fontWeight: 'bold', fontSize: '56px' }}>
      {value}
    </div>
    <div style={{ color: '#020623', fontFamily: 'Arial, sans-serif', fontWeight: 'bold', fontSize: '16px' }}>
      {label}
    </div>
    {sublabel && (
      <div style={{ color: '#89898C', fontFamily: 'Arial, sans-serif', fontSize: '13px', marginTop: '4px' }}>
        {sublabel}
      </div>
    )}
  </div>
);

// Footer
const EvolentFooter = ({ confidential = true }) => (
  <div
    className="text-right py-2 px-4"
    style={{ color: '#89898C', fontFamily: 'Arial, sans-serif', fontSize: '11px' }}
  >
    {confidential
      ? 'Evolent  |  Confidential—Do not distribute'
      : 'Evolent'
    }
  </div>
);
```

## Table Styling

```jsx
const EvolentTable = ({ headers, rows }) => (
  <table style={{ width: '100%', borderCollapse: 'collapse', fontFamily: 'Arial, sans-serif' }}>
    <thead>
      <tr>
        {headers.map((h, i) => (
          <th
            key={i}
            style={{
              backgroundColor: '#020623',
              color: '#FFFFFF',
              padding: '10px 12px',
              textAlign: 'left',
              fontSize: '13px',
              fontWeight: 'bold',
              borderBottom: '2px solid #020623',
            }}
          >
            {h}
          </th>
        ))}
      </tr>
    </thead>
    <tbody>
      {rows.map((row, ri) => (
        <tr key={ri} style={{ backgroundColor: ri % 2 === 0 ? '#FFFFFF' : '#F5F5F7' }}>
          {row.map((cell, ci) => (
            <td
              key={ci}
              style={{
                padding: '8px 12px',
                fontSize: '13px',
                color: '#020623',
                borderBottom: '1px solid #9FA7AE',
              }}
            >
              {cell}
            </td>
          ))}
        </tr>
      ))}
    </tbody>
  </table>
);
```

## Recharts Color Configuration

```jsx
const EVOLENT_CHART_COLORS = [
  '#5D3791',  // Deep Purple
  '#3475C1',  // Medium Blue
  '#17A5E6',  // Sky Blue
  '#08DCE2',  // Cyan
  '#4C51A6',  // Purple-Blue
  '#08F0D4',  // Mint
  '#7B1C92',  // Plum
];

// Usage with Recharts
<BarChart data={data}>
  <Bar dataKey="value1" fill={EVOLENT_CHART_COLORS[0]} />
  <Bar dataKey="value2" fill={EVOLENT_CHART_COLORS[1]} />
  <XAxis tick={{ fill: '#89898C', fontFamily: 'Arial', fontSize: 12 }} />
  <YAxis tick={{ fill: '#89898C', fontFamily: 'Arial', fontSize: 12 }} />
</BarChart>
```

## Page Layout Pattern

```html
<!-- Standard Evolent page layout -->
<div style="min-height: 100vh; background: #FFFFFF; font-family: Arial, Helvetica, sans-serif;">
  <!-- Gradient bar -->
  <div style="height: 4px; background: linear-gradient(to right, #5D3791, #692483, #4C51A6, #3475C1, #17A5E6, #09C9EE, #08DCE2, #08F0D4);"></div>

  <!-- Header -->
  <header style="padding: 20px 40px; border-bottom: 1px solid #F5F5F7;">
    <span style="color: #020623; font-size: 20px; font-weight: bold;">Evolent</span>
    <span style="color: #89898C; font-size: 14px; margin-left: 12px;">Specializing in Connected Care™</span>
  </header>

  <!-- Main content -->
  <main style="padding: 40px; max-width: 1200px; margin: 0 auto;">
    <!-- Content here -->
  </main>

  <!-- Footer -->
  <footer style="padding: 16px 40px; border-top: 1px solid #F5F5F7; text-align: right; color: #89898C; font-size: 11px;">
    Evolent  |  Confidential—Do not distribute
  </footer>
</div>
```
