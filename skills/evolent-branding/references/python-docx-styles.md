# Evolent python-docx Reference

When creating Evolent-branded Word documents using python-docx, use these constants and patterns.

## Color Constants

```python
from docx.shared import Pt, Inches, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT

class EvolentColors:
    NAVY = RGBColor(0x02, 0x06, 0x23)
    WHITE = RGBColor(0xFF, 0xFF, 0xFF)
    PLUM = RGBColor(0x7B, 0x1C, 0x92)
    COOL_GRAY = RGBColor(0x9F, 0xA7, 0xAE)
    MID_GRAY = RGBColor(0x89, 0x89, 0x8C)
    DEEP_PURPLE = RGBColor(0x5D, 0x37, 0x91)
    PURPLE_BLUE = RGBColor(0x4C, 0x51, 0xA6)
    BLUE = RGBColor(0x34, 0x75, 0xC1)
    SKY_BLUE = RGBColor(0x17, 0xA5, 0xE6)
    CYAN = RGBColor(0x08, 0xDC, 0xE2)
    MINT = RGBColor(0x08, 0xF0, 0xD4)
    BG_ALT = RGBColor(0xF5, 0xF5, 0xF7)
```

## Style Configuration

Apply these styles after creating the document:

```python
def configure_evolent_styles(doc):
    """Configure document styles to match Evolent branding."""
    style = doc.styles['Normal']
    font = style.font
    font.name = 'Arial'
    font.size = Pt(11)
    font.color.rgb = EvolentColors.NAVY

    # Heading 1
    h1 = doc.styles['Heading 1']
    h1.font.name = 'Arial'
    h1.font.size = Pt(18)
    h1.font.bold = True
    h1.font.color.rgb = EvolentColors.NAVY
    h1.paragraph_format.space_before = Pt(18)
    h1.paragraph_format.space_after = Pt(6)

    # Heading 2
    h2 = doc.styles['Heading 2']
    h2.font.name = 'Arial'
    h2.font.size = Pt(14)
    h2.font.bold = True
    h2.font.color.rgb = EvolentColors.DEEP_PURPLE
    h2.paragraph_format.space_before = Pt(12)
    h2.paragraph_format.space_after = Pt(4)

    # Heading 3
    h3 = doc.styles['Heading 3']
    h3.font.name = 'Arial'
    h3.font.size = Pt(12)
    h3.font.bold = True
    h3.font.color.rgb = EvolentColors.NAVY
    h3.paragraph_format.space_before = Pt(10)
    h3.paragraph_format.space_after = Pt(4)

    return doc
```

## Table Styling

```python
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

def style_evolent_table(table):
    """Apply Evolent branding to a python-docx table."""
    table.alignment = WD_TABLE_ALIGNMENT.LEFT

    for i, row in enumerate(table.rows):
        for cell in row.cells:
            # Font
            for paragraph in cell.paragraphs:
                for run in paragraph.runs:
                    run.font.name = 'Arial'
                    run.font.size = Pt(10)

            if i == 0:
                # Header row: navy background, white text
                shading = OxmlElement('w:shd')
                shading.set(qn('w:fill'), '020623')
                cell._tc.get_or_add_tcPr().append(shading)
                for paragraph in cell.paragraphs:
                    for run in paragraph.runs:
                        run.font.color.rgb = EvolentColors.WHITE
                        run.font.bold = True
                        run.font.size = Pt(10)
            elif i % 2 == 0:
                # Even rows: light gray
                shading = OxmlElement('w:shd')
                shading.set(qn('w:fill'), 'F5F5F7')
                cell._tc.get_or_add_tcPr().append(shading)
```

## Footer

```python
def add_evolent_footer(doc, confidential=True):
    """Add Evolent footer to all sections."""
    for section in doc.sections:
        footer = section.footer
        footer.is_linked_to_previous = False
        p = footer.paragraphs[0] if footer.paragraphs else footer.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.RIGHT

        if confidential:
            run = p.add_run('Evolent  |  Confidential—Do not distribute')
        else:
            run = p.add_run('Evolent')

        run.font.name = 'Arial'
        run.font.size = Pt(8)
        run.font.color.rgb = EvolentColors.MID_GRAY
```

## Page Setup

```python
def setup_evolent_page(doc):
    """Standard Evolent page margins and size."""
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(0.75)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
```
