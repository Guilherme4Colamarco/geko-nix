import re
import unittest
from pathlib import Path

SRC=Path(__file__).resolve().parents[1]/'src'
# `pleamar --check` accepts any family string and the runtime silently falls back,
# so a typo would only show up on screen. These are the families declared in
# modules/desktop/honey-common.nix (pkgs.nunito and google-fonts "Fredoka").
UI,DISPLAY='Nunito','Fredoka'
ELEMENT=re.compile(r'^\s*(text|input)\s+[^={]*\{(.*)\}\s*$')

def elements():
    for path in sorted(SRC.rglob('*.plm')):
        for n,line in enumerate(path.read_text().splitlines(),1):
            m=ELEMENT.match(line)
            if m: yield path.relative_to(SRC),n,line,m.group(2)

class FontTests(unittest.TestCase):
    def test_every_text_names_a_declared_family(self):
        seen=0
        for path,n,line,body in elements():
            seen+=1
            fam=re.search(r'family: "([^"]*)"',body)
            self.assertIsNotNone(fam,f'{path}:{n} sem family (cairia no sans-serif do sistema)')
            self.assertIn(fam.group(1),(UI,DISPLAY),f'{path}:{n}')
        self.assertGreater(seen,40)

    def test_fredoka_never_draws_a_live_number_as_one_text(self):
        # Fredoka digits are proportional (no tnum in pleamar): a live number in a
        # single text would change width. Only one digit per text is allowed.
        for path,n,line,body in elements():
            if f'family: "{DISPLAY}"' not in body: continue
            self.assertNotIn('clock.time',line,f'{path}:{n}')
            self.assertNotRegex(line,r'%|\{[^}]*\}[^"]*\{',f'{path}:{n}')

    def test_weights_stay_in_the_variable_ranges(self):
        ranges={UI:(200,1000),DISPLAY:(300,700)}
        for path,n,line,body in elements():
            fam=re.search(r'family: "([^"]*)"',body).group(1)
            w=re.search(r'weight: (\d+)',body)
            if w and fam in ranges: self.assertTrue(ranges[fam][0]<=int(w.group(1))<=ranges[fam][1],f'{path}:{n}')

if __name__=='__main__':
    unittest.main()
