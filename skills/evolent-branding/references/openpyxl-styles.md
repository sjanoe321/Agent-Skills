# Evolent openpyxl Reference

When creating Evolent-branded Excel workbooks, use these constants and patterns.

## Color Constants

```python
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side

class EvolentXL:
    # Fill colors
    NAVY_FILL = PatternFill(start_color='020623', end_color='020623', fill_type='solid')
    PURPLE_FILL = PatternFill(start_color='5D3791', end_color='5D3791', fill_type='solid')
    ALT_ROW_FILL = PatternFill(start_color='F5F5F7', end_color='F5F5F7', fill_type='solid')
    PLUM_FILL = PatternFill(start_color='7B1C92', end_color='7B1C92', fill_type='solid')
    LIGHT_PURPLE_FILL = PatternFill(start_color='EDE6F3', end_color='EDE6F3', fill_type='solid')

    # Fonts
    HEADER_FONT = Font(name='Arial', bold=True, size=11, color='FFFFFF')
    BODY_FONT = Font(name='Arial', size=11, color='020623')
    TITLE_FONT = Font(name='Arial', bold=True, size=14, color='020623')
    SUBTITLE_FONT = Font(name='Arial', size=12, color='5D3791')
    FOOTER_FONT = Font(name='Arial', size=8, color='89898C')
    LINK_FONT = Font(name='Arial', size=11, color='3475C1', underline='single')
    POSITIVE_FONT = Font(name='Arial', bold=True, size=11, color='08886E')
    NEGATIVE_FONT = Font(name='Arial', bold=True, size=11, color='7B1C92')

    # Borders
    THIN_BORDER = Border(
        left=Side(style='thin', color='9FA7AE'),
        right=Side(style='thin', color='9FA7AE'),
        top=Side(style='thin', color='9FA7AE'),
        bottom=Side(style='thin', color='9FA7AE'),
    )
    BOTTOM_BORDER = Border(
        bottom=Side(style='medium', color='020623'),
    )
```

## Apply Header Row

```python
def style_evolent_header(ws, row_num=1, max_col=None):
    """Style a header row with Evolent navy background and white text."""
    if max_col is None:
        max_col = ws.max_column
    for col in range(1, max_col + 1):
        cell = ws.cell(row=row_num, column=col)
        cell.fill = EvolentXL.NAVY_FILL
        cell.font = EvolentXL.HEADER_FONT
        cell.alignment = Alignment(horizontal='left', vertical='center', wrap_text=True)
        cell.border = EvolentXL.THIN_BORDER
```

## Apply Alternating Rows

```python
def style_evolent_body(ws, start_row=2, max_col=None):
    """Apply alternating row shading and Evolent body font."""
    if max_col is None:
        max_col = ws.max_column
    for row in range(start_row, ws.max_row + 1):
        for col in range(1, max_col + 1):
            cell = ws.cell(row=row, column=col)
            cell.font = EvolentXL.BODY_FONT
            cell.border = EvolentXL.THIN_BORDER
            cell.alignment = Alignment(vertical='center', wrap_text=True)
            if row % 2 == 0:
                cell.fill = EvolentXL.ALT_ROW_FILL
```

## Chart Colors (for openpyxl charts)

```python
EVOLENT_CHART_SERIES_COLORS = [
    '5D3791',  # Deep Purple
    '3475C1',  # Medium Blue
    '17A5E6',  # Sky Blue
    '08DCE2',  # Cyan
    '4C51A6',  # Purple-Blue
    '08F0D4',  # Mint
    '7B1C92',  # Plum
]
```
