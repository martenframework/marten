---
title: Create custom commands
description: How to create custom management commands.
---

Marten lets you create custom management commands as part of your [applications](../applications.md). This allows you to contribute new features and behaviors to the Marten CLI.

## Basic management command definition

Custom management commands are defined as subclasses of the [`Marten::CLI::Command`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html) abstract class. Such subclasses should be defined in a `cli/` folder at the root of the application, and it should be ensured that they are required by your `cli.cr` file (see [Creating applications](../applications.md#creating-applications) for more details regarding the structure of an application).

Management command classes must at least define a [`#run`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#run-instance-method) method, which will be called when the subcommand is executed:

```crystal
class MyCommand < Marten::CLI::Command
  help "Command that does something"

  def run
    # Do something
  end
end
```

As you can see in the previous example, the [`#help`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#help(help%3AString)-class-method) class method allows setting a "help text" that will be displayed when the help information of the command is requested.

If the above command was part of an installed application, it could be executed by using the Marten CLI as follows:

```bash
marten my_command
```

## Accepting options and arguments

Marten management commands can accept options and arguments. These differ and may be used for different use cases:

* options usually use the `-h` / `--help` style and can receive arguments if needed. They can be specified in any order
* arguments are _positional_ and only their values must be specified

By default options and arguments are always optional. That being said, they can be made mandatory in the command execution logic if needed.

Both options and arguments must be specified in the optional [`#setup`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#setup-instance-method) method: this method will be called to prepare the definition of the command, including its arguments and options.

For example:

```crystal
class MyCommand < Marten::CLI::Command
  help "Command that does something"

  @arg1 : String?
  @example : Bool = false

  def setup
    on_argument(:arg1, "The first argument") { |v| @arg1 = v }
    on_option("example", "An example option") { @example = true }
  end

  def run
    # Do something
  end
end
```

In the above example, the [`#on_argument`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#on_argument(name%3AString|Symbol%2Cdescription%3AString%2C%26block%3AString->)-instance-method) instance method is used to define an `arg1` argument. This method requires an argument name, an associated help text, and a proc where the value of the argument will be forwarded at execution time (which allows you to assign it to an instance variable or process it if you wish to). Similarly, the [`#on_option`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#on_option(flag%3AString|Symbol%2Cdescription%3AString%2C%26block%3AString->)-instance-method) instance method is used to define an `example` option.  In this case, the name of the option and its associated help text must be specified, and a proc can be defined to identify that the option was specified at execution time (which can be used to set a related boolean instance variable for example).

The above command would produce the following help information:

```
Usage: marten my_command [options] [arg1]

Command that does something

Arguments:
    arg1                             The first argument

Options:
    --example                        An example option
    --error-trace                    Show full error trace (if a compilation is involved)
    --no-color                       Disable colored output
    -h, --help                       Show this help
```

### Configuring options

As mentioned previously, it is possible to make use of the [`#on_option`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#on_option(flag%3AString|Symbol%2Cdescription%3AString%2C%26block%3AString->)-instance-method) instance method to configure a specific command option (eg. `--option`). It expects a flag name and a description, and it yields a block to let the command properly assign the option value to the command object at execution time:

```crystal
on_option("example", "An example option") { @example = true }
```

Note that the `--` must not be included in the option name.

Alternatively, it is possible to specify options that accept both a short flag (eg. `-h`) and a long flag (eg. `--help`):

```crystal
on_option("e", "example", "An example option") { @example = true }
```

### Configuring options that accept arguments

It is possible to make use of the [`#on_option_with_arg`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#on_option_with_arg(flag%3AString|Symbol%2Carg%3AString|Symbol%2Cdescription%3AString%2C%26block%3AString->)-instance-method) instance method to configure a specific command option with an associated argument. This method will configure a command option (eg. `--option`) and an associated argument. It expects a flag name, an argument name, and a description. It yields a block to let the command properly assign the option to the command object at execution time:

```crystal
on_option_with_arg(:option, :arg, "The name of the option") { @arg = arg }
```

Alternatively, it is possible to specify options that accept both a short flag (eg. `-h`) and a long flag (eg. `--help`):

```crystal
on_option_with_arg("o", "option", "arg", "The name of the option") { |arg| @arg = arg }
```

### Configuring arguments

As mentioned previously, it is possible to make use of the [`#on_argument`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#on_argument(name%3AString|Symbol%2Cdescription%3AString%2C%26block%3AString->)-instance-method) instance method in order to configure a specific command argument. This method expects an argument name and a description, and it yields a block to let the command properly assign the argument value to the command object at execution time:

```crystal
on_argument(:arg, "The name of the argument") { |value| @arg_var = value }
```

:::caution
It should be noted that the order in which arguments are defined is important: this order corresponds to the order in which arguments will need to be specified when invoking the subcommand.
:::

## Outputting text contents

When writing management commands, you will likely need to write text contents to the output file descriptor. To do so, you can make use of the [`#print`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#print(msg%2Cending%3D"\n")-instance-method) instance method:

```crystal
class HelloWorldCommand < Marten::CLI::Command
  help "Command that prints Hello World!"

  def run
    print("Hello World!")
  end
end
```

It should be noted that you can also choose to "style" the content you specify to [`#print`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#print(msg%2Cending%3D"\n")-instance-method) by wrapping your string with a call to the [`#style`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#style(msg%2Cfore%3Dnil%2Cmode%3Dnil)-instance-method) method. For example:

```crystal
class HelloWorldCommand < Marten::CLI::Command
  help "Command that prints Hello World!"

  def run
    print(style("Hello World!", fore: :light_blue, mode: :bold))
  end
end
```

As you can see, the [`#style`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#style(msg%2Cfore%3Dnil%2Cmode%3Dnil)-instance-method) method can be used to apply `fore` and `mode` styles to a specific text value. The values you can use for the `fore` and `mode` arguments are the same as the ones that you can use with the [`Colorize`](https://crystal-lang.org/api/Colorize.html) module (which comes with the standard library).

## Handling error cases

You will likely want to handle error situations when writing management commands. For example, to return error messages if a specified argument is not provided or if it is invalid. To do so you can make use of the [`#print_error`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#print_error(msg)-instance-method) helper method, which will print the passed string to the error file descriptor:

```crystal
class HelloWorldCommand < Marten::CLI::Command
  help "Command that prints Hello World!"

  @name : String?

  def setup
    on_argument(:name, "A name") { |v| @name = v }
  end

  def run
    if @name.nil?
      print_error("A name must be provided!")
    else
      print("Hello World, #{@name}!")
    end
  end
end
```

Alternatively, you can make use of the [`#print_error_and_exit`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#print_error_and_exit(msg%2Cexit_code%3D1)-instance-method) method to print a message to the error file descriptor and to exit the execution of the command.

## Customizing the subcommand name

By default, management command names are inferred by using their associated class names (eg. a `MyCommand` command class would translate to a `my_command` subcommand). That being said, it should be noted that you can define a custom subcommand name by leveraging the [`#command_name`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#command_name(name%3AString|Symbol)-class-method) class method:

```crystal
class MyCommand < Marten::CLI::Command
  command_name :dummycommand
  help "Command that does something"

  def run
    # Do something
  end
end
```

It is also worth mentioning that command aliases can be configured easily by using the [`#command_aliases`](pathname:///api/0.4/Marten/CLI/Manage/Command/Base.html#command_aliases(*aliases%3AString|Symbol)-class-method) helper method. For example:

```crystal
class MyCommand < Marten::CLI::Command
  command_name :test
  command_aliases :t
  help "Command that does something"

  def run
    # Do something
  end
end
```
