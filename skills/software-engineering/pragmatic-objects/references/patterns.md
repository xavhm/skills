# Patterns — catalogue d'objets

Sources : *Always Valid*, *Wrapper*, *Command*, *Procedural Object*, *Compute Object*, *Snapshot*, *Value Object*, *Observability* — book.pragmatic-objects.com

## Sommaire
- [Always Valid](#always-valid)
- [Value Object](#value-object)
- [Wrapper](#wrapper)
- [Command](#command)
- [Procedural Object](#procedural-object)
- [Compute Object](#compute-object)
- [Snapshot](#snapshot)
- [Observability](#observability)
- [Quel pattern choisir ?](#quel-pattern-choisir)

## Always Valid

**Intention** : garantir qu'un objet ne peut **jamais** exister dans un état invalide — la validation se fait exclusivement au constructeur (ou à la factory statique), jamais après coup.

```typescript
class Duration {
  constructor(private readonly value: number) {
    if (this.value < 0) throw new Error("value can't be negative");
  }
}
```

Combiné presque systématiquement avec [Value Object](#value-object). Supprime toute une classe de bugs liés aux objets "temporairement invalides" entre leur création et leur validation.

## Value Object

**Intention** : encapsuler une valeur primitive pour lui donner un sens et un comportement métier.

Propriétés qui le définissent :
- **Immuable** par définition — toute opération retourne une nouvelle instance.
- **Sans identité** : deux Value Objects portant la même valeur sont égaux (égalité structurelle, pas par référence).
- Contient souvent des opérations arithmétiques/comparaisons (`add`, `eq`, `gt`...).
- S'associe naturellement à [Always Valid](#always-valid) pour la validation à la construction.

```typescript
class Seconds {
  constructor(private value: number) { if (value < 0) throw new Error(...); }
  static minutes(v: number) { return new Seconds(v * 60); }
  equals(other: Seconds) { return this.value === other.value; }
  difference(other: Seconds) { return new Seconds(Math.abs(this.value - other.value)); }
}
```

## Wrapper

**Intention** : envelopper un objet/valeur pour permettre la **décoration composable** — généralisation du Value Object avec une seule méthode d'exposition (`expose()`).

```typescript
interface IWrapped<T> { expose(): T; }

class Identity<T> implements IWrapped<T> {
  constructor(private readonly value: T) {}
  expose() { return this.value; }
}

abstract class Wrapper<T> implements IWrapped<T> {
  constructor(protected readonly value: IWrapped<T>) {}
  abstract expose(): T;
}

class LowerCase extends Wrapper<string> { expose() { return this.value.expose().toLowerCase(); } }
class Slugify extends Wrapper<string> { expose() { return this.value.expose().replace(/[^a-zA-Z0-9-]/g, '-'); } }

// Composition libre des décorateurs :
new Slugify(new LowerCase(new Identity('Hello World'))).expose(); // "hello-world"
```

Chaque décorateur est en général un [Compute Object](#compute-object) ; la valeur enveloppée en base est souvent un [Value Object](#value-object).

## Command

**Intention** : représenter **une action unique** du système, découplée du "God Service" fourre-tout.

Antipattern visé :
```typescript
class UserService { register() {} update() {} ban() {} remove() {} getInfo() {} getPurchaseHistory() {} }
```

Pattern recommandé :
```typescript
class RegisterCommand {
  constructor(public readonly emailAddress: string, public readonly password: string) {}
}
class RegisterCommandHandler {
  execute(command: RegisterCommand) { /* ... */ }
}
```

- Un `Command` = une intention métier + ses données (souvent en lecture seule).
- Un `CommandHandler` = l'objet qui l'exécute, avec ses collaborateurs propres (respecte l'**Interface Segregation** par construction : chaque handler ne dépend que de ce dont il a besoin).
- Chaque `Command` est une **unité de test naturelle** — bien adapté au TDD.
- Équivalent au principe **UseCase**, central dans la Clean Architecture : chaque comportement documenté par un objet nommé dans la structure de dossiers.

## Procedural Object

**Intention** : représenter explicitement une **procédure** plutôt que de laisser du code procédural "flotter" hors de tout objet.

Exemples typiques : un algorithme (tri, allocation de ressource, recherche d'itinéraire), un `CommandHandler` d'application, une action HTTP. Différence clé avec un objet de domaine "riche" : c'est assumé comme un objet **de flux**, pas un objet **vivant** porteur d'identité/état métier.

## Compute Object

**Intention** : encapsuler un **calcul/une formule** dans un objet nommé plutôt que de la laisser procédurale dans une méthode utilitaire.

```typescript
class CreditsToPay {
  constructor(private readonly duration: Duration) {}
  amount() { return this.duration.asHours() * 2; } // calcul lazy, à l'appel
}
```

⚠️ Statut : un **pis-aller assumé**, pas l'idéal object. C'est mieux que du code procédural nu, mais si une solution "vivante" existe (ex. extension par héritage type `UsersCollection.legalUsers()`, cf. [`practices-structure.md`](practices-structure.md#quand-lhéritage-concret-a-du-sens)), elle est préférable. À utiliser **quand il n'y a rien de mieux sous la main**.

## Snapshot

**Intention** : représenter **l'état public** d'un objet à un instant T, pour la persistance ou la sérialisation — jamais pour un usage interne au domaine.

Contrat à respecter : `Xxx.fromSnapshot(obj.snapshot()) === obj` (égalité logique).

```typescript
type Snapshot = { id: string; creditPoints: number; schedule: GetSnapshot<Schedule> };

class Student extends Entity<State, Snapshot> {
  static fromSnapshot(snapshot: Snapshot): Student { /* reconstruit */ }
  snapshot(): Snapshot { /* extrait */ }
}
```

Structure composite : un objet contenant d'autres objets doit propager `snapshot()`/`fromSnapshot()` récursivement (interface "Snapshottable" implicite). Détails d'usage → [`practices-encapsulation.md#expose-snapshots`](practices-encapsulation.md#expose-snapshots).

## Observability

**Intention** : permettre à des objets de **collaborer en choréographie** (pub/sub) plutôt qu'être coordonnés par un chef d'orchestre.

```typescript
class ChatBox {
  receiveMessages(messages: Message[]) { this.eventDispatcher.emit("newMessages", messages); }
}
class NavigationBar {
  constructor(eventDispatcher) {
    eventDispatcher.on("newMessages", this.incrementUnreadMessages.bind(this));
  }
}
```

Aucun objet ne connaît l'autre directement ; les deux évoluent indépendamment tant que le contrat d'événement est respecté. Modèle de référence : les microservices communiquant en asynchrone. Voir aussi [`practices-structure.md#inherit-wisely`](practices-structure.md#inherit-wisely) pour la version "délégation" utilisée comme alternative à l'héritage.

## Quel pattern choisir ?

| Besoin | Pattern |
|---|---|
| Une primitive porte une règle/un comportement métier | Value Object (+ Always Valid) |
| Garantir qu'un objet n'existe jamais en état invalide | Always Valid |
| Composer des transformations sur une valeur | Wrapper |
| Une action/un cas d'usage du système | Command (+ Handler) |
| Un algorithme ou une action technique (HTTP, etc.) sans richesse métier | Procedural Object |
| Un calcul/une formule sans "meilleure" solution objet disponible | Compute Object *(pis-aller assumé)* |
| Exposer un objet de domaine vers la persistance/API | Snapshot |
| Faire collaborer des objets sans chef d'orchestre | Observability |
