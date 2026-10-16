# Exemples travaillés — avant / après

Sources : *What's an Object?*, *Thinking Object*, *Celsiuses/Fahrenheits* — book.pragmatic-objects.com

## Sommaire
- [Le nombre mystère (magic number)](#le-nombre-mystère-magic-number)
- [Réservation d'auto-école — la "vue à 100 pieds"](#réservation-dauto-école--la-vue-à-100-pieds)
- [Celsius ⇄ Fahrenheit](#celsius--fahrenheit)
- [Gilded Rose (mutation) — pointeur](#gilded-rose-mutation--pointeur)

## Le nombre mystère (magic number)

**Avant — 100% procédural**, tout dans une seule fonction, aucun objet :
```typescript
async function magicNumber() {
  let magicNumber = Math.floor(Math.random() * 100) + 1;
  let userNumber = -1;
  while (userNumber !== magicNumber) {
    const { guess } = await prompt.get(['guess']);
    userNumber = parseInt(guess as string, 10);
    if (userNumber > magicNumber) console.log('Too big');
    else if (userNumber < magicNumber) console.log('Too small !');
    else console.log('You won !');
  }
}
```

**Après — orienté objet**, chaque concept devient un objet responsable de son propre comportement :
```typescript
interface GameEvents { tooBig(): void; tooSmall(): void; match(): void; }

class MagicNumber {
  private value = Math.floor(Math.random() * 100) + 1;
  constructor(private readonly events: GameEvents) {}
  compare(guess: Guess) {
    if (guess.isGreaterThan(this.value)) this.events.tooBig();
    else if (guess.isLessThan(this.value)) this.events.tooSmall();
    else this.events.match();
  }
}

interface AttemptSource { nextAttempt(): Promise<number>; }

class Guess {
  private value!: number;
  constructor(private readonly source: AttemptSource) {}
  async start() { this.value = await this.source.nextAttempt(); }
  isGreaterThan(v: number) { return this.value > v; }
  isLessThan(v: number) { return this.value < v; }
}

class Game implements GameEvents {
  private running = true;
  private source = new ConsoleAttemptSource();
  private magicNumber = new MagicNumber(this);

  run() {
    while (this.running) {
      const guess = new Guess(this.source);
      this.magicNumber.compare(guess);
    }
  }
  tooBig() { console.log('The number is too big'); }
  tooSmall() { console.log('The number is too small'); }
  match() { console.log('You won'); this.running = false; }
}
```

**Ce qui a changé, et pourquoi ça compte** :
- `Game.run()` tient en **4 lignes** — c'est la seule "vue d'ensemble" du programme, entièrement lisible.
- `Game` ne sait **rien** de comment `MagicNumber` est généré, ni de comment `Guess` récupère sa valeur (console, réseau, IA...) — pur découplage par interfaces (`AttemptSource`, `GameEvents`).
- Aucun objet n'interroge l'état interne d'un autre : ils **se parlent** (`isGreaterThan`, `compare`) plutôt que de **s'extraire mutuellement leurs valeurs**.
- Pour un programme aussi trivial, la version objet est objectivement plus verbeuse — **c'est assumé** : l'exemple illustre le principe sur un cas volontairement simple, le gain se matérialise à mesure que la complexité métier grandit.

→ Détail complet du raisonnement encapsulation : [`practices-encapsulation.md`](practices-encapsulation.md#no-getters--setters).

## Réservation d'auto-école — la "vue à 100 pieds"

Illustration qu'un cas d'usage **peut rester procédural en surface** tant que les objets manipulés sont riches :

```typescript
const student = Students.find("student-id");
const instructor = Instructors.find("instructor-id");

Invariants.check(student.isAvailable(date), "the student is not available");
Invariants.check(student.hasEnoughCredits(), "your balance of credit is insufficient");
Invariants.check(instructor.isAvailable(date), "the instructor is not available");

const car = garage.allocate(date);
const creditsToPay = new CreditsToPay(date, new Duration(durationInHours));
const lesson = Lesson.reserve(student, instructor, car, date);

student.consumeCredits(creditsToPay);
student.addToSchedule(lesson);
instructor.addToSchedule(lesson);
```

**Leçon clé** : le "brief métier" est lui-même procédural ("d'abord vérifier ceci, puis faire cela") — forcer ce flux en objets serait artificiel. Ce qui doit rester objet, c'est **ce que chaque étape manipule** (`Student`, `CreditsToPay`, `Lesson`...), pas nécessairement l'enchaînement lui-même. Ce type de classe orchestratrice est un [Procedural Object](patterns.md#procedural-object) légitime — cf. Application Service / Command Handler.

Toute nouvelle règle métier (limite de 2 sessions/semaine, jours de congé des moniteurs...) s'ajoute **sans toucher aux autres objets** — chaque règle vit dans l'objet concerné.

## Celsius ⇄ Fahrenheit

**Avant** (C#-like, getter/setter avec conversion cachée) :
```csharp
public class Thermostat {
  private double temperatureFahrenheit;
  public double temperatureCelsius {
    get { return (temperatureFahrenheit - 32) * 5 / 9; }
    set {
      if (value < -273.15) throw new ArgumentException("...");
      temperatureFahrenheit = (value * 9 / 5) + 32;
    }
  }
}
```
Problèmes identifiés : unité (Celsius/Fahrenheit) traitée comme un **suffixe de nom** au lieu d'un **type** ; le setter recalcule silencieusement une autre grandeur ; le getter recalcule à chaque appel (coût caché) ; `Thermostat` porte une responsabilité (conversion) qui n'est pas la sienne.

**Méthode** : partir du **brief** en langage naturel → en extraire noms (objets) et verbes (comportement).
> *"On veut un programme pour convertir des Fahrenheits en Celsius et inversement."*

**Après** :
```typescript
class Celsius {
  constructor(private readonly value: number) {
    if (value < -273.15) throw new Error('Celsius cannot be below the absolute zero');
  }
  toFahrenheits() { return new Fahrenheit(this.value * 1.8 + 32); }
}

class Fahrenheit {
  constructor(private readonly value: number) {
    if (value < -459.67) throw new Error('Fahrenheit cannot be below the absolute zero');
  }
  toCelsiuses() { return new Celsius((this.value - 32) / 1.8); }
}
```

Points clés :
- La dépendance circulaire (`Celsius` connaît `Fahrenheit` et vice-versa) est **acceptée sans problème** : chacun est seul légitime à savoir comment se transformer en l'autre.
- La validation (zéro absolu) est portée par **chaque** classe — chacune protège ses propres invariants ([Always Valid](patterns.md#always-valid)).
- `Celsius` et `Fahrenheit` sont deux [Value Objects](patterns.md#value-object), pas des synonymes d'un `double`.

## Gilded Rose (mutation) — pointeur

Exemple canonique sur la discipline de mutation, détaillé dans [`practices-modeling.md#immutabilité`](practices-modeling.md#immutabilité) : regrouper toute mutation en un seul point via un `delta` calculé par des fonctions pures nommées, plutôt que de muter en cascade dans des conditions imbriquées.
