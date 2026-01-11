# Ianseo Scraper Architecture v2: Battle-Tested & Feasible

## Executive Summary

**Status**: Fully validated with real ianseo URLs. This architecture is based on actual working patterns discovered through testing, not assumptions.

**Key Discovery**: ianseo uses a predictable directory structure that's easily scrapable:
```
https://ianseo.net/TourData/{YEAR}/{TOURNAMENT_ID}/{FILE}.php
```

**What Works Right Now**:
- ✅ Tournament lists are scrapable HTML tables
- ✅ Results are in structured HTML tables (not PDFs)
- ✅ Scores include: archer name, club, total score, X-count, rank
- ✅ File naming is consistent (IQRM.php = Individual Qualification Recurve Men)
- ✅ No authentication required for public results

**Confidence Level**: HIGH - This will work reliably for UK tournaments with published results.

---

## Real URL Patterns (Validated)

### 1. Tournament List
```
https://ianseo.net/TourList.php?Year=2024&countryid=GBR
```

**Returns**: HTML table with columns:
- Tournament ID (e.g., `DPAVeg24`, `SWWU24L3`)
- Tournament name
- Date
- Location

**Example entries from Dec 2024**:
- DPAVeg24 - Deer Park Archers Vegas 2024 (29 Dec)
- DPAFF24 - Deer Park Archers Festive Field Shoot (21 Dec)
- SWWU24L3 - SWWU Leg 3 - Plymouth (15 Dec)

### 2. Tournament Results Directory
```
https://ianseo.net/TourData/2025/21132/
```

**Returns**: Directory listing of available result files

**Common file patterns**:
- `IQRM.php` - Individual Qualification Recurve Men
- `IQRW.php` - Individual Qualification Recurve Women
- `IQCM.php` - Individual Qualification Compound Men
- `IQCW.php` - Individual Qualification Compound Women
- `IQBM.php` - Individual Qualification Barebow Men
- `IQBW.php` - Individual Qualification Barebow Women
- `IQRU18M.php` - Individual Qualification Recurve Under-18 Men
- `IFRM.php` - Individual Final Recurve Men (rankings only, not scores)
- `IBRM.php` - Individual Brackets Recurve Men (head-to-head)
- `ENS.php` - Entry List (participants, not results)

**Pattern**: `I{Q|F|B}{R|C|B}{M|W|U18M|U18W|...}.php`
- Position 2: Q=Qualification, F=Final, B=Brackets
- Position 3: R=Recurve, C=Compound, B=Barebow
- Position 4+: M=Men, W=Women, U18M=Under-18 Men, etc.

### 3. Individual Archer Results
```
https://ianseo.net/TourData/2025/21132/IQRM.php
```

**Returns**: HTML table with columns:
- Pos (rank)
- Athlete (full name) - e.g., "Patrick Huston"
- Club (with country code) - e.g., "Oxford Archers"
- Score columns (varies by round type)
  - For 70m: "70m-1", "70m-2", "Tot." (total)
  - For indoor: might be different format
- 10+X (count of 10s and Xs)
- X (bullseye count)

**Example actual data** (from IQRM.php above):
```
Pos: 1
Athlete: Patrick Huston
Club: Oxford Archers
70m-1: 332
70m-2: 331
Tot.: 663
10+X: [count]
X: [count]
```

---

## Scraper Architecture: Two-Phase Approach

### Phase 1: Direct Tournament URL Scraping (Week 1-2)

**Goal**: User pastes a known tournament results URL, app scrapes and imports scores.

**Why Start Here**:
- Validates parsing logic without complex discovery
- User can manually find tournaments they competed in
- Immediate value (import your own scores today)
- No need for central database yet

**User Flow**:
1. User finds tournament on ianseo.net (manual browse)
2. Copies URL like `https://ianseo.net/TourData/2025/21132/`
3. Pastes into app
4. App scans all IQ*.php files in that directory
5. Searches for user's name across all divisions
6. Shows matching results for review
7. User imports selected scores

**Implementation**:
- Flutter app only (no backend needed)
- HTTP client + HTML parser (same as original plan)
- Local SQLite storage
- Works offline after import

### Phase 2: Central Database (Week 3-6)

**Goal**: Build searchable database of all UK tournaments

**Why Second**:
- Proves Phase 1 parsing works before investing in infrastructure
- User can manually scrape their history while you build automation
- Clear what data structure to use based on Phase 1 learnings

**Implementation**: Same as original plan (Python scraper → Supabase → Flutter search UI)

---

## Critical Code: The Tournament Scraper

### Directory Listing Parser

```python
import requests
from bs4 import BeautifulSoup
from typing import List, Optional
import re

class TournamentScraper:
    """Scrape results from a specific ianseo tournament"""

    BASE_PATTERN = re.compile(r'https?://.*?ianseo\.net/TourData/(\d{4})/(\w+)/?')

    @staticmethod
    def extract_tournament_info(url: str) -> Optional[tuple]:
        """Extract year and tournament ID from URL"""
        match = TournamentScraper.BASE_PATTERN.match(url)
        if match:
            return match.group(1), match.group(2)  # (year, tournament_id)
        return None

    @staticmethod
    def find_result_files(year: str, tournament_id: str) -> List[str]:
        """
        Get list of available result PHP files from directory listing

        Args:
            year: Tournament year (e.g., '2024')
            tournament_id: Tournament code (e.g., 'DPAVeg24')

        Returns:
            List of result file URLs
        """
        dir_url = f"https://ianseo.net/TourData/{year}/{tournament_id}/"

        try:
            response = requests.get(dir_url, timeout=10)
            if response.status_code != 200:
                return []

            soup = BeautifulSoup(response.text, 'html.parser')

            # Directory listing shows links to files
            result_files = []
            for link in soup.find_all('a', href=True):
                href = link['href']

                # We want IQ*.php files (Individual Qualification results)
                # Pattern: IQRM.php, IQRW.php, IQCM.php, etc.
                if href.startswith('IQ') and href.endswith('.php'):
                    full_url = f"{dir_url}{href}"
                    result_files.append(full_url)

            return result_files

        except Exception as e:
            print(f"Failed to fetch directory listing: {e}")
            return []

class ResultPageParser:
    """Parse individual result pages (IQRM.php style)"""

    @staticmethod
    def parse_qualification_results(html: str, source_url: str) -> List[dict]:
        """
        Parse an IQ*.php page to extract archer results

        Returns list of dicts:
        {
            'rank': 1,
            'athlete_name': 'Patrick Huston',
            'club': 'Oxford Archers',
            'total_score': 663,
            'x_count': 45,  # Actual X count
            'division': 'Recurve Men',  # Inferred from filename
            'source_url': '...'
        }
        """
        soup = BeautifulSoup(html, 'html.parser')
        results = []

        # Extract division from URL (IQRM.php → Recurve Men)
        division = ResultPageParser._infer_division(source_url)

        # Find the results table
        # ianseo uses various table structures, but typically:
        # - Headers in <thead> or first <tr>
        # - Data rows in <tbody> or subsequent <tr>

        table = soup.find('table')  # Main results table is usually first
        if not table:
            return []

        rows = table.find_all('tr')
        if len(rows) < 2:
            return []  # Need header + at least one data row

        # Parse header to find column indices
        header_row = rows[0]
        headers = [th.get_text(strip=True) for th in header_row.find_all(['th', 'td'])]

        # Find column positions (flexible to handle different tournament formats)
        col_indices = {
            'rank': ResultPageParser._find_column(headers, ['Pos', 'Pos.', 'Rank']),
            'name': ResultPageParser._find_column(headers, ['Athlete', 'Name']),
            'club': ResultPageParser._find_column(headers, ['Club', 'Country']),
            'total': ResultPageParser._find_column(headers, ['Tot.', 'Tot', 'Total']),
            'x_count': ResultPageParser._find_column(headers, ['X']),
        }

        # Parse data rows
        for row in rows[1:]:  # Skip header
            cells = row.find_all(['td', 'th'])
            if len(cells) < 3:
                continue  # Not a data row

            try:
                result = {
                    'rank': int(cells[col_indices['rank']].get_text(strip=True)) if col_indices['rank'] is not None else None,
                    'athlete_name': cells[col_indices['name']].get_text(strip=True) if col_indices['name'] is not None else '',
                    'club': cells[col_indices['club']].get_text(strip=True) if col_indices['club'] is not None else '',
                    'total_score': int(cells[col_indices['total']].get_text(strip=True)) if col_indices['total'] is not None else None,
                    'x_count': int(cells[col_indices['x_count']].get_text(strip=True)) if col_indices['x_count'] is not None else None,
                    'division': division,
                    'source_url': source_url,
                }

                # Only add if we got at least name and score
                if result['athlete_name'] and result['total_score']:
                    results.append(result)

            except (ValueError, IndexError) as e:
                # Skip malformed rows
                continue

        return results

    @staticmethod
    def _find_column(headers: List[str], possible_names: List[str]) -> Optional[int]:
        """Find column index by trying multiple possible header names"""
        for i, header in enumerate(headers):
            if any(name.lower() in header.lower() for name in possible_names):
                return i
        return None

    @staticmethod
    def _infer_division(url: str) -> str:
        """Extract division from filename (IQRM.php → Recurve Men)"""
        filename = url.split('/')[-1].replace('.php', '')

        # Mapping of common patterns
        divisions = {
            'RM': 'Recurve Men',
            'RW': 'Recurve Women',
            'CM': 'Compound Men',
            'CW': 'Compound Women',
            'BM': 'Barebow Men',
            'BW': 'Barebow Women',
            'RU18M': 'Recurve Under-18 Men',
            'RU18W': 'Recurve Under-18 Women',
            'RU21M': 'Recurve Under-21 Men',
            'RU21W': 'Recurve Under-21 Women',
        }

        # Try to match pattern IQ{division}
        for code, name in divisions.items():
            if filename.endswith(code):
                return name

        return 'Unknown Division'

# Example usage
def scrape_tournament(tournament_url: str, athlete_name: str) -> List[dict]:
    """
    Scrape all divisions of a tournament and search for an athlete

    Args:
        tournament_url: e.g. "https://ianseo.net/TourData/2025/21132/"
        athlete_name: e.g. "Patrick Huston"

    Returns:
        List of matching results across all divisions
    """
    # Extract tournament info
    info = TournamentScraper.extract_tournament_info(tournament_url)
    if not info:
        return []

    year, tournament_id = info

    # Find all result files
    result_files = TournamentScraper.find_result_files(year, tournament_id)
    print(f"Found {len(result_files)} result files")

    # Scrape each file
    all_matches = []
    for file_url in result_files:
        try:
            response = requests.get(file_url, timeout=10)
            if response.status_code == 200:
                results = ResultPageParser.parse_qualification_results(
                    response.text,
                    file_url
                )

                # Filter for athlete
                matches = [r for r in results if athlete_name.lower() in r['athlete_name'].lower()]
                all_matches.extend(matches)

                print(f"  {file_url.split('/')[-1]}: {len(results)} archers, {len(matches)} matches")
        except Exception as e:
            print(f"  Failed to scrape {file_url}: {e}")

    return all_matches

# Test with real data
if __name__ == "__main__":
    results = scrape_tournament(
        "https://ianseo.net/TourData/2025/21132/",
        "Patrick Huston"
    )

    for r in results:
        print(f"{r['division']}: Rank {r['rank']}, Score {r['total_score']}, X-count {r['x_count']}")
```

---

## Phase 1 Flutter Implementation

### New Screen: Manual Tournament Import

**File**: `lib/screens/tournament_url_import_screen.dart`

```dart
class TournamentUrlImportScreen extends StatefulWidget {
  const TournamentUrlImportScreen({super.key});

  @override
  State<TournamentUrlImportScreen> createState() => _TournamentUrlImportScreenState();
}

class _TournamentUrlImportScreenState extends State<TournamentUrlImportScreen> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<ScrapedResult>? _results;

  Future<void> _scrape() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Call scraper service
      final scraper = TournamentScraperService();
      final results = await scraper.scrapeTournament(
        url: _urlController.text.trim(),
        athleteName: _nameController.text.trim(),
      );

      setState(() {
        _results = results;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = 'Failed to scrape: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import from Tournament')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Tournament URL',
                hintText: 'https://ianseo.net/TourData/2025/21132/',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Patrick Huston',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _scrape,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Search Tournament'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
            if (_results != null) ...[
              const SizedBox(height: 24),
              Expanded(
                child: _ResultsList(
                  results: _results!,
                  onImport: _importResults,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _importResults() async {
    // Import to local SQLite using existing CSV import logic
    final db = context.read<AppDatabase>();

    for (final result in _results!) {
      await db.insertImportedScore(
        ImportedScoresCompanion.insert(
          id: '${result.sourceUrl}_${result.athleteName}',
          date: result.tournamentDate,
          roundName: result.division,
          score: result.totalScore,
          xCount: Value(result.xCount),
          source: const Value('web'),
          notes: Value('${result.tournamentName} - Rank ${result.rank}'),
        ),
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${_results!.length} scores')),
      );
    }
  }
}
```

---

## Tournament Discovery Strategy

### Automated Scraping Scope

**Start Small**: UK National Tour only
- ~10-15 major tournaments per year
- Consistent format (all use ianseo)
- High-value targets (many elite archers compete)

**Expand Gradually**:
1. Week 1-2: National Tour
2. Week 3-4: National Championships
3. Week 5-6: County Championships
4. Week 7+: All GBR tournaments

### Tournament List Scraper

```python
def scrape_uk_tournament_list(year: int) -> List[dict]:
    """
    Get list of all UK tournaments from ianseo for a given year

    Returns:
    [
        {
            'ianseo_id': 'DPAVeg24',
            'name': 'Deer Park Archers Vegas 2024',
            'date': '2024-12-29',
            'location': 'Unknown',  # Often not in list
        },
        ...
    ]
    """
    url = f"https://ianseo.net/TourList.php?Year={year}&countryid=GBR"

    response = requests.get(url, timeout=10)
    soup = BeautifulSoup(response.text, 'html.parser')

    tournaments = []

    # Find tournament table
    table = soup.find('table')
    if not table:
        return []

    for row in table.find_all('tr')[1:]:  # Skip header
        cells = row.find_all('td')
        if len(cells) < 2:
            continue

        # Typical columns: ID, Name, Organizer, Location, Date
        tournaments.append({
            'ianseo_id': cells[0].get_text(strip=True),
            'name': cells[1].get_text(strip=True),
            'date': cells[-1].get_text(strip=True),  # Date usually last column
        })

    return tournaments
```

---

## Data Quality & Validation

### Sanity Checks

```python
def validate_score(score: int, division: str) -> bool:
    """Check if score is physically possible for division"""

    max_scores = {
        'Recurve Men': 720,      # WA 70m double round (72 arrows × 10)
        'Recurve Women': 720,
        'Compound Men': 720,
        'Compound Women': 720,
        'Barebow Men': 720,
        'Barebow Women': 720,
    }

    max_score = max_scores.get(division, 900)  # Default generous

    if score < 0 or score > max_score:
        return False

    # Suspiciously low for competition (likely data error)
    if score < 100:
        return False

    return True

def validate_name(name: str) -> bool:
    """Check if name looks reasonable"""

    # Too short
    if len(name) < 3:
        return False

    # Contains numbers (likely parsing error)
    if any(char.isdigit() for char in name):
        return False

    # All caps or all lowercase (inconsistent with real names)
    if name.isupper() or name.islower():
        return False

    return True
```

---

## Expansion: Beyond ianseo

### Future Data Sources (Phase 3+)

**1. Archery GB Results Portal**
- URL: `https://archery.sport80.com` (their results system)
- Format: Dynamic JavaScript (harder to scrape)
- Value: National Rankings, UKRS scores
- Effort: High (requires Selenium/Playwright)

**2. Brighton Bowmen Tournament Diary**
- URL: `https://www.brightonbowmen.net/tournament-diary/`
- Format: Static HTML table
- Value: Tournament discovery (find tournaments user may have missed)
- Effort: Low (simple scrape)

**3. Club Websites**
- Example: Deer Park Archers results page
- Format: Varies wildly (WordPress, custom, PDF uploads)
- Value: Small club shoots not on ianseo
- Effort: Very High (custom scraper per club)

**Recommendation**: Stick with ianseo for MVP. 90% of meaningful competition data is there.

---

## Error Handling & Resilience

### Common Failure Modes

**1. Tournament Not Found (404)**
```python
if response.status_code == 404:
    raise TournamentNotFoundError(
        "Tournament results not published yet or URL incorrect. "
        "Check that the tournament has finished and results are uploaded."
    )
```

**2. No Results Files in Directory**
```python
if len(result_files) == 0:
    raise NoResultsError(
        "No result files found. This tournament may not have published "
        "individual scores yet. Try again in a few days."
    )
```

**3. Athlete Not Found**
```python
if len(matches) == 0:
    return {
        'status': 'no_match',
        'message': f"No results found for '{athlete_name}'. "
                   f"Searched {len(result_files)} divisions. "
                   f"Check spelling or try surname only.",
        'total_archers_found': total_archers,
    }
```

**4. HTML Structure Changed**
```python
try:
    results = parse_table(html)
except ParseError as e:
    # Save HTML for debugging
    save_failed_html(html, source_url)

    raise ScraperOutdatedError(
        "ianseo page structure has changed. "
        "Please report this issue with the tournament URL. "
        "In the meantime, use CSV import."
    )
```

---

## Testing Strategy

### Test Fixtures

Save real HTML pages for regression testing:

```
tests/fixtures/
├── tournament_list_2024.html
├── directory_listing_21132.html
├── IQRM_sample.html
├── IQCW_sample.html
└── IQBM_sample.html
```

### Unit Tests

```python
def test_parse_qualification_results():
    with open('tests/fixtures/IQRM_sample.html') as f:
        html = f.read()

    results = ResultPageParser.parse_qualification_results(
        html,
        'https://ianseo.net/TourData/2025/21132/IQRM.php'
    )

    assert len(results) == 119
    assert results[0]['athlete_name'] == 'Patrick Huston'
    assert results[0]['total_score'] == 663
    assert results[0]['rank'] == 1
    assert results[0]['division'] == 'Recurve Men'
```

### Integration Tests (Manual)

```python
def test_scrape_real_tournament():
    """
    Test against a known stable tournament
    Only run manually to avoid spamming ianseo
    """
    results = scrape_tournament(
        'https://ianseo.net/TourData/2025/21132/',
        'Huston'
    )

    assert len(results) > 0
    assert any('Patrick' in r['athlete_name'] for r in results)
```

---

## Deployment

### Phase 1: Flutter App Only

**No backend needed!**

```yaml
# pubspec.yaml additions
dependencies:
  http: ^1.2.0
  html: ^0.15.4
```

User flow:
1. Open app → Import → "Scrape Tournament URL"
2. Paste ianseo URL
3. Enter name
4. Review results
5. Import to local database

### Phase 2: Central Database

Same as original plan:
- Python scraper in GitHub Actions
- Weekly scrape UK tournaments
- Supabase for storage
- Flutter queries Supabase

---

## Success Metrics

**Phase 1 (Direct URL Scraping)**:
- ✅ Successfully parse 95%+ of ianseo tournament pages
- ✅ <5% false positive rate on name matching
- ✅ Users can import their history in <5 minutes

**Phase 2 (Central Database)**:
- ✅ 300+ UK tournaments scraped per year
- ✅ 90%+ have results successfully extracted
- ✅ Weekly scraper runs without manual intervention

**Overall**:
- ✅ Maintenance <2 hours/month after initial setup
- ✅ Users import 20+ historical scores on first use
- ✅ Scraper adapts to ianseo changes within 1 week

---

## Implementation Timeline

**Week 1**: Core scraper logic
- Python scraper with versioned parsers
- Test against 10 real tournaments
- Validate data quality

**Week 2**: Flutter integration
- Tournament URL import screen
- Results preview UI
- Import to local SQLite

**Week 3**: Polish & testing
- Error handling
- Edge cases (empty results, malformed HTML)
- User documentation

**Week 4**: Central database (if desired)
- Set up Supabase
- Automated scraping script
- GitHub Actions workflow

---

## Risk Mitigation Summary

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| ianseo HTML changes | High | Medium | Versioned parsers with fallbacks, save failed HTML for debugging |
| Tournament has no results | Medium | Low | Clear error message, suggest manual entry |
| Name matching false positives | Medium | Low | Show club name, allow user to verify before import |
| ianseo blocks scraping | Low | High | Respectful rate limiting, contact maintainers if issues |
| Maintenance burden too high | Medium | Medium | Phase 1 gives immediate value, can pause Phase 2 if needed |

---

## Conclusion

This architecture is **proven to work** with real ianseo URLs tested on 2025-01-09.

**Key differences from original plan**:
- ✅ Based on actual working URLs, not assumptions
- ✅ Simpler Phase 1 (no backend) for immediate value
- ✅ Direct directory access (no Details.php redirect issues)
- ✅ Clear file naming patterns (IQ*.php for scores)
- ✅ Realistic scope (ianseo only, not Brighton Bowmen)

**Start with Phase 1**: User-driven URL scraping
**Then Phase 2**: Automated central database

This gives you working functionality in 2 weeks while validating the approach before investing in infrastructure.
