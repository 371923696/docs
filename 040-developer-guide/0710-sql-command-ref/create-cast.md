# CREATE CAST

定义一种新的造型。

## 概要

```
CREATE CAST (sourcetype AS targettype) 
       WITH FUNCTION funcname (argtypes) 
       [AS ASSIGNMENT | AS IMPLICIT]

CREATE CAST (sourcetype AS targettype) WITHOUT FUNCTION 
       [AS ASSIGNMENT | AS IMPLICIT]
```

## 描述

CREATE CAST 定义一种新的造型。一种造型指定如何在两种数据类型之间执行转换。例如，

```
SELECT CAST(42 AS text);
```

通过调用一个之前指定的函数将整数常量 42 转换成类型 text ，这种情况下是 text\(int4\)。 如果没有定义合适的造型， 该转换会失败。

两种类型可以是二进制可兼容，这表示他们可以不调用任何函数而转化为另外一个。这要求相应的值使用同样的内部表示，例如,类型 text 和 varchar 二进制可兼容。

默认情况下，只有一次显式造型请求才会调用造型， 形式是 `CAST(x AS typename)` 或 `x:: typename` 构造。

如果造型被标记为 AS ASSIGNMENT 那么在为一个目标数据类型的列赋值时会隐式地调用它。例如，假设 foo.f1 是一类型为 text 的列, 则:

```
INSERT INTO foo (f1) VALUES (42);
```

将被允许如果从类型 integer 到类型 text 的造型被标记为 AS ASSIGNMENT, 否则不会允许。 我们通常使用 _赋值造型_ 来描述此类造型。

如果造型被标记为 AS IMPLICIT 那么可以在任何上下文中隐式地调用它，无论是赋值还是在一个表达式内部。 我们通常用术语 _隐式造型_ 来描述这类造型。例如，因为 \|\| 需要 text 操作数,

```
SELECT 'The time is ' || now();
```

将被允许如果从类型 timestamp 到类型 text 的造型被标记为 AS IMPLICIT. 否则，有必要明确地写出转换，例如

```
SELECT 'The time is ' || CAST(now() AS text);
```

对标记造型为隐式持保守态度是明智的。过多的隐式造型路径可能导致  HashData 数据库以令人吃惊的方式解释命令，或者由于有多种可能解释而根本无法解析命令。 一种好的经验是让一种造型只对于同一种一般类型分类中的类型间的信息保持转换隐式可调用。 例如， 从 int2 到 int4 的造型可以被合理地标记为隐式，, 但是从 float8 到 int4 的造型可能应该只能在赋值时使用。 跨类型分类的造型如 text 到 int4, 最好只被用于显式使用。

为了能够创建一个造型，用户必须拥有源或目标数据类型。要创建二进制兼容的造型，用户必须是超级用户。

## 参数

_sourcetype_

该造型的源数据类型的名称。

_targettype_

该造型的目标数据类型的名称。

_funcname\(argtypes\)_

被用于执行该造型的函数。函数名称可以用方案限定。如果没有被限定， 将在模式搜索路径中查找该函数。 函数的结果数据类型必须是该造型的目标数据类型。

造型实现函数可以具有 1 到 3 个参数。 第一个参数类型必须等于源类型或者能从源类型二进制强制得到。 第二个参数（如果存在）必须是类型 integer; 它接收与目标类型相关联的类型修饰符，如果没有类型修饰符，它会收到 -1 。第三个参数, （如果存在）必须是类型 boolean; 如果该造型是一种显式造型，它会收到 true 否则会收 false 。SQL 标准在某些情况中对显式和隐式造型要求不同的行为。这个参数被提供给必须实现这 类造型的函数。不推荐在设计自己的数据类型时用它）

通常，造型必须具有不同的源和目标数据类型。 但是，如果具有多个参数的造型实现函数，则允许声明具有相同源和目标类型的造型。 这用于表示系统目录中的特定类型的长度强制功能。 named函数用于将类型的值强制为由其第二个参数给出的类型修饰符值。 \(由于语法目前仅允许某些内置数据类型具有类型修饰符，因此此功能对用户定义的目标类型无效。\)

当一个造型具有不同的源和目标类型和一个需要多个参数的函数时，它支持从一个类型转换为另一个类型，并在一个步骤中应用长度强制。 当没有这样的条目可用时， 强制使用类型修饰符的类型涉及两个转换步骤，一个用于在数据类型之间转换，另一个用于应用修饰符。

WITHOUT FUNCTION

指示源类型可以二进制强制到目标类型，因此执行该造型不需要函数。

AS ASSIGNMENT

指示该造型可以在赋值的情况下被隐式调用。

AS IMPLICIT

指示该造型可以在任何上下文中被隐式调用。

## 注解

请注意，在此版本的 HashData 数据库中，用户定义的造型中使用的用户定义函数必须定义为IMMUTABLE 。必须将用于自定义函数的任何编译代码（共享库文件）放置在 HashData  Database 数组（主数据库和所有段）中每个主机上的相同位置。 这个位置也必须在 LD\_LIBRARY\_PATH 以便服务器可以找到文件。

记住如果用户想要能够双向转换类型，用户需要在两个方向上都显式声明造型。

建议用户遵循在目标数据类型之后命名操行实现函数的惯例，因为内置的操行实现函数能被命名。 许多用户习惯于使用函数式符号来造型数据类型，也就是说 `typename(x)`。

## 示例

要使用函数 `int4(text）` 创建一种从类型 text 到类型 int4 的赋值造型\(在系统中这种造型已经被预定义。\):

```
CREATE CAST (text AS int4) WITH FUNCTION int4(text);
```

## 兼容性

CREATE CAST 命令符合 SQL 标准， 不过 SQL 没有为二进制可兼容类型或者实现函数的额外参数做好准备。 AS IMPLICIT 也是一种 HashData 数据库的扩展。

## 另见

[CREATE FUNCTION](./create-function.md)，[CREATE TYPE](./create-type.md)， [DROP CAST](./drop-cast.md)

**上级主题：** [SQL命令参考](./README.md)

