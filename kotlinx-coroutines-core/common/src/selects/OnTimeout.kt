/*
 * Copyright 2016-2021 JetBrains s.r.o. Use of this source code is governed by the Apache 2.0 license.
 */

package kotlinx.coroutines.selects

import kotlinx.coroutines.*
import kotlin.time.*

/**
 * We implement [SelectBuilder.onTimeout] as a clause, with the only difference
 * that it requires access to the coroutine context to get a proper [Delay] instance.
 * Thus, we use an unchecked cast to [SelectImplementation] and storing the context
 * in the [corresponding field][SelectImplementation.context].
 */
private class OnTimeout(
    private val timeMillis: Long
) {
    private fun register(select: SelectInstance<*>, ignoredParam: Any?) {
        // Should this clause complete immediately?
        if (timeMillis <= 0) {
            select.selectInRegPhase(Unit)
            return
        }
        // Invoke `trySelect` after the timeout is reached.
        val action = Runnable {
            select.trySelect(this@OnTimeout, Unit)
        }
        select as SelectImplementation<*>
        val context = select.context
        val disposableHandle = context.delay.invokeOnTimeout(timeMillis, action, context)
        // Do not forget to clean-up when this `select` is completed or cancelled.
        select.invokeOnCompletion { disposableHandle.dispose() }
    }

    val selectClause: SelectClause0
        get() = SelectClause0Impl(
            clauseObject = this@OnTimeout,
            regFunc = OnTimeout::register as RegistrationFunction
        )
}

/**
 * Clause that selects the given [block] after a specified timeout passes.
 * If timeout is negative or zero, [block] is selected immediately.
 *
 * **Note: This is an experimental api.** It may be replaced with light-weight timer/timeout channels in the future.
 *
 * @param timeMillis timeout time in milliseconds.
 */
@ExperimentalCoroutinesApi
@Suppress("EXTENSION_SHADOWED_BY_MEMBER")
public fun <R> SelectBuilder<R>.onTimeout(timeMillis: Long, block: suspend () -> R): Unit =
    OnTimeout(timeMillis).selectClause.invoke(block)

/**
 * Clause that selects the given [block] after the specified [timeout] passes.
 * If timeout is negative or zero, [block] is selected immediately.
 *
 * **Note: This is an experimental api.** It may be replaced with light-weight timer/timeout channels in the future.
 */
@ExperimentalCoroutinesApi
@ExperimentalTime
public fun <R> SelectBuilder<R>.onTimeout(timeout: Duration, block: suspend () -> R): Unit =
    onTimeout(timeout.toDelayMillis(), block)