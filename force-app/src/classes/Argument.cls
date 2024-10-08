/*
 * Copyright (c) 2022, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

/**
 * Matchable offers public static methods to build out-of-the-box matchers to be used with Expect
 *    - Argument.any()
 *    - Argument.equals(Object object)
 *    - Argument.jsonEquals(Object object)
 *    - Argument.ofType(String typeName)
 *    - Argument.ofType(Type type)
 *    - Argument.ofType(Schema.SObjectType sobjectType)
 */
@IsTest
@SuppressWarnings('PMD.EmptyStatementBlock, PMD.AvoidGlobalModifier')
global class Argument {
  global interface Matchable {
    Boolean matches(Object callArgument);
  }

  global class ConfigurationException extends Exception {
  }

  private Argument() {
  }

  public static boolean matches(final List<Argument.Matchable> matchableArguments, final List<Object> callArguments) {
    if (matchableArguments == null || callArguments == null) {
      // If both equals null then return true
      return matchableArguments == callArguments;
    }

    if (matchableArguments.size() != callArguments.size()) {
      return false;
    }

    for (Integer i = 0; i < matchableArguments.size(); ++i) {
      if (!matchableArguments[i].matches(callArguments[i])) {
        return false;
      }
    }

    return true;
  }

  global static List<Argument.Matchable> empty() {
    return new List<Argument.Matchable>();
  }

  global static List<Argument.Matchable> of(final Object arg) {
    return Argument.ofList(new List<Object>{ arg });
  }

  global static List<Argument.Matchable> of(final Object arg1, final Object arg2) {
    return Argument.ofList(new List<Object>{ arg1, arg2 });
  }

  global static List<Argument.Matchable> of(final Object arg1, final Object arg2, final Object arg3) {
    return Argument.ofList(new List<Object>{ arg1, arg2, arg3 });
  }

  global static List<Argument.Matchable> of(final Object arg1, final Object arg2, final Object arg3, final Object arg4) {
    return Argument.ofList(new List<Object>{ arg1, arg2, arg3, arg4 });
  }

  global static List<Argument.Matchable> of(final Object arg1, final Object arg2, final Object arg3, final Object arg4, final Object arg5) {
    return Argument.ofList(new List<Object>{ arg1, arg2, arg3, arg4, arg5 });
  }

  global static List<Argument.Matchable> ofList(final List<Object> listOfArgs) {
    final List<Argument.Matchable> listOfMatchableArgs = Argument.empty();
    if (listOfArgs == null) {
      return listOfMatchableArgs;
    }
    for (Object callArgument : listOfArgs) {
      if (callArgument instanceof Argument.Matchable) {
        listOfMatchableArgs.add((Argument.Matchable) callArgument);
      } else {
        listOfMatchableArgs.add(Argument.equals(callArgument));
      }
    }
    return listOfMatchableArgs;
  }

  global static Argument.Matchable any() {
    return new AnyMatchable();
  }

  global static Argument.Matchable equals(final Object callArgument) {
    return new EqualsMatchable(callArgument);
  }

  global static Argument.Matchable jsonEquals(final Object callArgument) {
    return new JSONMatchable(callArgument);
  }

  global static Argument.Matchable ofType(final String matchingType) {
    return new TypeMatchable(matchingType);
  }

  global static Argument.Matchable ofType(final Schema.SObjectType callArgument) {
    return new TypeMatchable(callArgument);
  }

  global static Argument.Matchable ofType(final Type callArgument) {
    return new TypeMatchable(callArgument);
  }

  private class AnyMatchable implements Argument.Matchable {
    public Boolean matches(final Object callArgument) {
      return true;
    }

    public override String toString() {
      return 'any';
    }
  }

  private class EqualsMatchable implements Argument.Matchable {
    private Object callArgumentToMatch;

    public EqualsMatchable(final Object callArgumentToMatch) {
      this.callArgumentToMatch = callArgumentToMatch;
    }

    public Boolean matches(final Object callArgument) {
      if (this.callArgumentToMatch == null) {
        return callArgument == null;
      }

      // case-sensitive check for string
      if (this.callArgumentToMatch instanceof String) {
        return this.callArgumentToMatch.equals(callArgument);
      }

      // native platform equality check for anything else
      return this.callArgumentToMatch == callArgument;
    }

    public override String toString() {
      return String.valueOf(this.callArgumentToMatch);
    }
  }

  private class JSONMatchable implements Argument.Matchable {
    private Object callArgumentToMatch;
    private String jsonValue;

    public JSONMatchable(final Object callArgumentToMatch) {
      this.callArgumentToMatch = callArgumentToMatch;
      this.jsonValue = JSON.serialize(callArgumentToMatch);
    }

    public Boolean matches(final Object callArgument) {
      return this.jsonValue.equals(JSON.serialize(callArgument));
    }

    public override String toString() {
      return 'json(' + this.callArgumentToMatch + ')';
    }
  }

  private class TypeMatchable implements Argument.Matchable {
    private String typeNameToMatch;

    public TypeMatchable(final Schema.SObjectType callArgumentToMatch) {
      this.typeNameToMatch = callArgumentToMatch.getDescribe().getName();
    }

    public TypeMatchable(final String callArgumentToMatch) {
      this.typeNameToMatch = callArgumentToMatch;
    }

    public TypeMatchable(final Type callArgumentToMatch) {
      this.typeNameToMatch = callArgumentToMatch.getName();
    }

    public boolean matches(final Object callArgument) {
      String typeName = this.getType(callArgument);
      // Using a case-insensitive comparison since Apex types are case-insensitive
      if (this.typeNameToMatch == typeName) {
        return true;
      }

      Type actualType = Type.forName(typeName);
      Type expectedType = Type.forName(this.typeNameToMatch);
      if (expectedType != null && actualType != null) {
        return expectedType.isAssignableFrom(actualType);
      }
      return false;
    }

    private String getType(final Object callArgument) {
      try {
        // Cast as Date to determine if Object is a valid Date.
        Date typeCheck = (Date) callArgument; // NOPMD
        return 'Date';
      } catch (System.TypeException te) {
        // If not a Date, extract Type output from exception message.
        return te.getMessage().substringBetween('Invalid conversion from runtime type ', ' to Date');
      }
    }

    public override String toString() {
      return this.typeNameToMatch + '.Type';
    }
  }
}
