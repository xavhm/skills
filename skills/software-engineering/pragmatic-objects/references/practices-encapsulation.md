# Pratiques — Encapsulation

Sources : *No Getters & Setters*, *Minimize Knowledge*, *Don't Check Types*, *Expose Snapshots*, *Abandon Composed Names* — book.pragmatic-objects.com

## Sommaire
- [No Getters & Setters](#no-getters--setters)
- [Minimize Knowledge (Loi de Déméter)](#minimize-knowledge-loi-de-déméter)
- [Don't Check Types](#dont-check-types)
- [Expose Snapshots](#expose-snapshots)
- [Abandon Composed Names](#abandon-composed-names)

## No Getters & Setters

**Getters** : exposer une valeur interne casse l'encapsulation, quel que soit le prétexte.

3 raisons légitimes de vouloir "sortir" une info, et leur solution à chaque fois :

| Besoin | Mauvaise solution | Bonne solution |
|---|---|---|
| Effectuer une action avec la valeur | `if (guess.get() > this.value)` | Déléguer le comportement à l'objet : `guess.isGreaterThan(this.value)` |
| Créer un autre objet à partir de la valeur | `new CreditsToPay(duration.getValue() / 3600)` | Passer l'objet lui-même : `new CreditsToPay(duration)`, laisser `CreditsToPay` appeler `duration.toHours()` |
| Exposer vers l'extérieur du système | getter brut | Pattern [Expose Snapshots](#expose-snapshots) |

**Exemple canonique** (jeu du nombre mystère) :
```typescript
// Mauvais : MagicNumber arrache la valeur de Guess
compare(guess: Guess) {
  const guessed = guess.get();
  if (guessed > this.value) { this.events.tooBig(); }
}

// Bon : Guess sait comparer lui-même
compare(guess: Guess) {
  if (guess.isGreaterThan(this.value)) { this.events.tooBig(); }
}
```

**Setters** : un setter expose une mutation "nue", sans intention métier. Deux problèmes cumulés :
1. Il traite l'objet comme une coquille de données inerte au lieu de lui laisser porter le comportement (`duration.add(60)` plutôt que get/mutate/set).
2. Même `add(value: number)` reste faible : pourquoi un `Duration` accepterait-il un nombre brut au lieu d'un autre `Duration` ? Les opérations sur un type doivent rester **closes** sur ce type (`duration.add(Duration.fromHours(1))`).

Poussé à son terme : si `Duration.fromSeconds(1) == Duration.fromSeconds(1)` doit être vrai (deux objets égaux s'ils portent la même valeur), alors `add` doit **retourner une nouvelle instance** plutôt que muter — c'est la propriété du [Value Object](patterns.md#value-object) et de l'[Immutabilité](practices-modeling.md#immutabilité).

```typescript
class Duration {
  add(duration: Duration): Duration {
    return Duration.fromSeconds(this.value + duration.value); // pas de mutation
  }
}
```

**Règle de nommage pour les mutations nécessaires** : préférer un verbe métier (`changeEmailAddress()`) à `setEmailAddress()`. Un verbe métier peut être enrichi de validations, règles métier, événements de domaine — un setter ne le suggère jamais.

## Minimize Knowledge (Loi de Déméter)

Principe : *Tell, Don't Ask*. Ne pas extraire un objet interne pour le manipuler depuis l'extérieur — demander à l'objet parent d'agir.

```typescript
// Mauvais : on sort le wallet, on le modifie de l'extérieur
user.getWallet().add(new Coins(10));

// Bon : on délègue à User
user.deposit(new Coins(10));
```

Gain : `User` peut changer d'implémentation interne (wallet → poche → paiement mobile) sans casser aucun appelant. Le contrat externe (`deposit`) reste stable ; seul le design interne change.

**Règles pratiques** :
- Ne jamais agir sur un objet qui fait partie de la représentation interne d'un autre objet ("ne pas parler au voisin du voisin").
- Il est normal de connaître les objets qu'on **crée et injecte soi-même** (collaborateurs directs).
- **Chaîner plus de 2 points/getters** (`a.b().c().d()`) est un signal fort que l'appelant en sait trop.
- Arbitrage à faire au cas par cas : exposer un sous-objet (ex. `Variant` d'une `Image`) est acceptable **si** cet objet est stable, a peu de raisons de changer, et a du sens en dehors de son parent. Sinon, garder le contrôle et exposer une API plus étroite (`image.add(name, url)` plutôt que `image.add(new Variant(...))`).

## Don't Check Types

`instanceof` / type-check casse le polymorphisme et introduit un couplage "qui sait tout" — l'inverse de l'ignorance object nécessaire pour le découplage.

Progression de refactoring typique (exemple : droits `BannedUser` / `RegularUser` / `AdminUser`) :

```typescript
// Niveau 0 — pire : type-checking explicite
if (user instanceof BannedUser) { throw new Error("..."); }

// Niveau 1 — mieux mais la classe parente connaît trop ses enfants
if (!user.isBanned()) { throw ... }

// Niveau 2 — bon : penser en "capacités" plutôt qu'en identité de type
if (!user.canUseApp()) { throw ... }
else if (!user.isAllMighty() && !something.isManageableBy(user)) { throw ... }
```

**Règle** : remplacer tout `instanceof`/`switch(type)` par une méthode polymorphique exprimant une **capacité** (`canX()`, `isManageableBy()`), jamais une identité de classe.

## Expose Snapshots

⚠️ Réservé aux **frontières du système** (sérialisation JSON, persistance). Ne jamais utiliser à l'intérieur du domaine — côté lecture/CQRS, interroger directement la base est souvent plus adapté.

Un objet expose volontairement une représentation plate de lui-même, via deux méthodes symétriques :

```typescript
type Snapshot = { id: string; creditPoints: number; schedule: GetSnapshot<Schedule> };

class Student extends Entity<State, Snapshot> {
  static fromSnapshot(snapshot: Snapshot): Student { /* reconstruit l'objet */ }
  snapshot(): Snapshot { /* extrait une vue plate */ }
}
```

Invariant à respecter : `Student.fromSnapshot(obj.snapshot()) == obj`.

C'est un compromis assumé : on casse un peu l'encapsulation (le domaine "sait" comment s'exposer), mais **le contrôle reste dans l'objet** — contrairement à des getters dispersés, un seul point de rupture à maintenir si la structure change. Les objets imbriqués doivent aussi être "Snapshottable" (composite).

Pour l'exposition en lecture pure (GET d'API), séparer explicitement lecture et écriture (**CQRS**) : le modèle de lecture (DTO/ViewModel) n'a pas à ressembler au modèle de domaine.

## Abandon Composed Names

Un nom composé (`userAge`, `movementSpeed`) est souvent le signe qu'**un objet manque** à l'appel.

Diagnostic :
- Si le nom composé regroupe des informations liées à une même entité → regrouper dans un objet (`user.age()` plutôt que `userAge`).
- Si la méthode traite l'âge de "choses différentes" → laisser les deux objets communiquer entre eux plutôt que de "servir" les deux depuis l'extérieur.
- Règle de Robert Martin (*Clean Code*) : **la longueur d'un nom de variable croît avec la portée de la méthode**. Un besoin récurrent de noms composés = signal que la méthode fait trop de choses → candidate à l'extraction de méthode ou de classe.

Exceptions légitimes : mots composés qui appartiennent réellement au vocabulaire du domaine (`paperBag`, `weekEnd`).
