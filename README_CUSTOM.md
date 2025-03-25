# Dynamic Data Factory pour Salesforce

Ce framework permet de générer des données de test dynamiques pour les environnements Salesforce, en respectant les relations entre les objets et en automatisant la création des données complexes.

## Fonctionnalités principales

- **Création dynamique d'objets** : Génération d'instances de n'importe quel type d'objet Salesforce
- **Gestion des relations** : Support des relations lookups et master-detail
- **Création récursive** : Création automatique des objets liés en cascade
- **Conversions automatiques** : Conversion des types de données appropriés (Date, DateTime, Boolean, etc.)
- **Gestion des RecordTypes** : Support pour les différents types d'enregistrements
- **Interface utilisateur** : Composant Lightning Web pour visualiser et gérer les configurations
- **Mode Bulk** : Génération en masse de données de test
- **Mode Récursif** : Extraction et réplication de hiérarchies d'objets existantes

## Architecture

Le framework s'appuie sur les composants clés suivants :

- **DynamicDataFactory** : Classe principale pour la création d'objets dynamiques
- **BulkTestDataGenerator** : Génération en masse avec gestion des lookups
- **RecursiveTestDataGenerator** : Création récursive à partir d'objets existants
- **SObjectTypeTestClasse__c** : Objet personnalisé stockant les configurations
- **SObjectTypeTestClasseComponent** (LWC) : Interface utilisateur pour gérer les configurations

## Installation

Déployez l'ensemble du projet dans votre org Salesforce :

```bash
sfdx force:source:deploy -p force-app -u votre-org
```

## Cas d'utilisation

### Créer un scénario de test complexe

Imaginons que vous deviez tester une fonctionnalité impliquant un processus commercial complexe avec plusieurs objets liés :

1. **Compte** → **Opportunité** → **Produits d'opportunité**
2. **Compte** → **Contact** → **Tâche**

Voici comment procéder :

#### 1. Définir les configurations d'objets

Tout d'abord, créez les enregistrements "header" dans l'objet `SObjectTypeTestClasse__c` :

```apex
// Compte header
SObjectTypeTestClasse__c accountHeader = new SObjectTypeTestClasse__c(
    Name = 'Account_Header',
    SObjectType__c = 'Account',
    lineType__c = 'header',
    LineOrder__c = 1,
    Attribute1__c = 'Name',
    Attribute2__c = 'Industry',
    Attribute3__c = 'Type'
);

// Opportunité header
SObjectTypeTestClasse__c oppHeader = new SObjectTypeTestClasse__c(
    Name = 'Opportunity_Header',
    SObjectType__c = 'Opportunity',
    lineType__c = 'header',
    LineOrder__c = 1,
    Attribute1__c = 'Name',
    Attribute2__c = 'StageName',
    Attribute3__c = 'CloseDate',
    Attribute4__c = 'AccountId'
);

// Contact header
SObjectTypeTestClasse__c contactHeader = new SObjectTypeTestClasse__c(
    Name = 'Contact_Header',
    SObjectType__c = 'Contact',
    lineType__c = 'header',
    LineOrder__c = 1,
    Attribute1__c = 'FirstName',
    Attribute2__c = 'LastName',
    Attribute3__c = 'Email',
    Attribute4__c = 'AccountId'
);

// Tâche header
SObjectTypeTestClasse__c taskHeader = new SObjectTypeTestClasse__c(
    Name = 'Task_Header',
    SObjectType__c = 'Task',
    lineType__c = 'header',
    LineOrder__c = 1,
    Attribute1__c = 'Subject',
    Attribute2__c = 'Status',
    Attribute3__c = 'Priority', 
    Attribute4__c = 'WhoId'
);

insert new List<SObjectTypeTestClasse__c>{accountHeader, oppHeader, contactHeader, taskHeader};
```

#### 2. Définir les valeurs de données

Créer vos données dans une static resource comme dans l'exemple de la static ressource dans le projet
ou executer directement  recursiveTestDataGenerator
```

#### 3. Générer les données
charger les données de la static resource
 List<Object> listName = System.Test.loadData(SObjectTypeTestClasse__c.sObjectType, 'DynamicDataFactory');
Utilisez le `DynamicDataFactory` pour générer les objets avec leurs relations :

```apex
// Instancier le factory
DynamicDataFactory factory = new DynamicDataFactory();

// Créer les objets de manière récursive, en résolvant automatiquement les relations
List<SObject> accounts = factory.createSobjectsCascadeLookup('Account');

// Vérifier les résultats
System.debug('Compte créé : ' + accounts[0]);
System.debug('ID du compte : ' + accounts[0].Id);

// Retrouver l'opportunité liée
List<Opportunity> opps = [SELECT Id, Name, AccountId FROM Opportunity WHERE AccountId = :accounts[0].Id];
System.debug('Opportunité créée : ' + opps);

// Retrouver le contact lié
List<Contact> contacts = [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE AccountId = :accounts[0].Id];
System.debug('Contact créé : ' + contacts);

// Retrouver la tâche liée au contact
List<Task> tasks = [SELECT Id, Subject, WhoId FROM Task WHERE WhoId = :contacts[0].Id];
System.debug('Tâche créée : ' + tasks);
```

#### 4. Générer des données en masse

Pour créer une grande quantité de données à partir d'enregistrements existants :

```apex
// Sélectionnez un enregistrement existant pour le cloner avec sa hiérarchie
Account existingAccount = [SELECT Id FROM Account WHERE Name = 'ACME Corporation' LIMIT 1];

// Génération en masse
BulkTestDataGenerator.generateTestDataWithLookups(new List<Id>{existingAccount.Id});
BulkTestDataGenerator.commitRecords();
```

#### 5. Extraire une structure depuis une donnée existante

Pour capturer la structure de données d'un enregistrement existant :

```apex
// Extraire un modèle à partir d'un enregistrement existant
Account existingAccount = [SELECT Id FROM Account WHERE Name = 'Client Exemple' LIMIT 1];

// Génération récursive
RecursiveTestDataGenerator.generateTestDataWithLookups(existingAccount.Id);
RecursiveTestDataGenerator.commitRecords();
```

### Interface utilisateur

Vous pouvez également utiliser le composant Lightning (LWC) pour visualiser et gérer vos configurations. Ajoutez le composant `sObjectTypeTestClasseComponent` à votre page Lightning :

```html
<c-s-object-type-test-classe-component></c-s-object-type-test-classe-component>
```

## Bonnes pratiques

- Créez d'abord les objets au sommet de la hiérarchie, puis descendez vers les objets enfants
- Utilisez des noms significatifs pour vos configurations en ligne
- Pour les dates, utilisez le format 'today' ou 'today:N' pour les dates relatives
- Pour les champs numériques, assurez-vous que les valeurs correspondent aux contraintes de validation

## Limitations

- La classe supporte jusqu'à 40 attributs par objet
- Certains types de champs complexes (formules, récapitulatifs) sont ignorés lors de la génération
- Les relations polymorphiques nécessitent une attention particulière

## Contribution

Les contributions à ce projet sont les bienvenues. N'hésitez pas à soumettre des pull requests ou à signaler des problèmes.

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.
